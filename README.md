# pgmin

A program that will minimize those pesky SQL queries for you so you can focus on more important things like reading Hacker News.

## Usage

Basic usage is:

```console
$ ./pgmin file.sql > file.min.sql
$ psql < file.sql
$ psql < file.min.sql  # same results!
```

The generated file can only be run in `psql` at this point, which certainly is more secure than whatever ridiculous method you were going to use already.  Plus `psql` is really what Real Hackers(tm) use, and you want to be a Real Hacker(tm), don't you?  Of course you do, that's why you're reading Hacker News.

## Example

Here is a [sample query](https://wiki.postgresql.org/wiki/Show_database_bloat) before `pgmin`:

```sql
SELECT
  current_database(), schemaname, tablename, /*reltuples::bigint, relpages::bigint, otta,*/
  ROUND((CASE WHEN otta=0 THEN 0.0 ELSE sml.relpages::float/otta END)::numeric,1) AS tbloat,
  CASE WHEN relpages < otta THEN 0 ELSE bs*(sml.relpages-otta)::BIGINT END AS wastedbytes,
  iname, /*ituples::bigint, ipages::bigint, iotta,*/
  ROUND((CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages::float/iotta END)::numeric,1) AS ibloat,
  CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END AS wastedibytes
FROM (
  SELECT
    schemaname, tablename, cc.reltuples, cc.relpages, bs,
    CEIL((cc.reltuples*((datahdr+ma-
      (CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta,
    COALESCE(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages,
    COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta -- very rough approximation, assumes all cols
  FROM (
    SELECT
      ma,bs,schemaname,tablename,
      (datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr,
      (maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
    FROM (
      SELECT
        schemaname, tablename, hdr, ma, bs,
        SUM((1-null_frac)*avg_width) AS datawidth,
        MAX(null_frac) AS maxfracsum,
        hdr+(
          SELECT 1+count(*)/8
          FROM pg_stats s2
          WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename
        ) AS nullhdr
      FROM pg_stats s, (
        SELECT
          (SELECT current_setting('block_size')::numeric) AS bs,
          CASE WHEN substring(v,12,3) IN ('8.0','8.1','8.2') THEN 27 ELSE 23 END AS hdr,
          CASE WHEN v ~ 'mingw32' THEN 8 ELSE 4 END AS ma
        FROM (SELECT version() AS v) AS foo
      ) AS constants
      GROUP BY 1,2,3,4,5
    ) AS foo
  ) AS rs
  JOIN pg_class cc ON cc.relname = rs.tablename
  JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = rs.schemaname AND nn.nspname <> 'information_schema'
  LEFT JOIN pg_index i ON indrelid = cc.oid
  LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid
) AS sml
ORDER BY wastedbytes DESC

```

And this same query after `pgmin`:

```sql
\set mJ and \set mw avg_width \set v bigint \set h case \set Cb ceil \set Cc coalesce \set Ti constants \set mR count \set m current_database \set mY current_setting \set CW datahdr \set CO datawidth \set Ts desc \set X else \set u end \set e float \set Ty foo \set Cx from \set TN group \set Cf hdr \set E ibloat \set x iname \set TD indexrelid \set TH indrelid \set V iotta \set g ipages \set CQ ituples \set Tb join \set Tc left \set mk max \set Cu maxfracsum \set TL nspname \set mM null_frac \set CU nullhdr \set Ck nullhdr2 \set o numeric \set TM oid \set Tv order \set K otta \set Tq pg_class \set TR pg_index \set TZ pg_namespace \set mP pg_stats \set CX relname \set Td relnamespace \set a relpages \set CN reltuples \set M round \set T schemaname \set C select \set H sml \set mI substring \set md sum \set P tablename \set Z tbloat \set b then \set TB version \set Y wastedbytes \set Cn wastedibytes \set f when \set mQ where 
 :C :m(),:T,:P,:M((:h :f :K=0 :b 0.0 :X :H.:a:::e/:K :u):::o,1)AS :Z,:h :f :a<:K :b 0 :X bs*(:H.:a-:K):::v :u AS :Y,:x,:M((:h :f :V=0 OR :g=0 :b 0.0 :X :g:::e/:V :u):::o,1)AS :E,:h :f :g<:V :b 0 :X bs*(:g-:V):u AS :Cn :Cx(:C :T,:P,cc.:CN,cc.:a,bs,:Cb((cc.:CN*((:CW+ma-(:h :f :CW%ma=0 :b ma :X :CW%ma :u))+:Ck+4))/(bs-20:::e))AS :K,:Cc(c2.:CX,'?')AS :x,:Cc(c2.:CN,0)AS :CQ,:Cc(c2.:a,0)AS :g,:Cc(:Cb((c2.:CN*(:CW-12))/(bs-20:::e)),0)AS :V :Cx(:C ma,bs,:T,:P,(:CO+(:Cf+ma-(:h :f :Cf%ma=0 :b ma :X :Cf%ma :u))):::o AS :CW,(:Cu*(:CU+ma-(:h :f :CU%ma=0 :b ma :X :CU%ma :u)))AS :Ck :Cx(:C :T,:P,:Cf,ma,bs,:md((1-:mM)*:mw)AS :CO,:mk(:mM)AS :Cu,:Cf+(:C 1+:mR(*)/8 :Cx :mP s2 :mQ :mM<>0 :mJ s2.:T=s.:T :mJ s2.:P=s.:P)AS :CU :Cx :mP s,(:C(:C :mY('block_size'):::o)AS bs,:h :f :mI(v,12,3)IN('8.0','8.1','8.2'):b 27 :X 23 :u AS :Cf,:h :f v~'mingw32' :b 8 :X 4 :u AS ma :Cx(:C :TB()AS v)AS :Ty)AS :Ti :TN BY 1,2,3,4,5)AS :Ty)AS rs :Tb :Tq cc ON cc.:CX=rs.:P :Tb :TZ nn ON cc.:Td=nn.:TM :mJ nn.:TL=rs.:T :mJ nn.:TL<>'information_schema' :Tc :Tb :TR i ON :TH=cc.:TM :Tc :Tb :Tq c2 ON c2.:TM=i.:TD)AS :H :Tv BY :Y :Ts
```

As you can see, it looks much smaller, which obviously makes this better.  Why wouldn't you want to do this?  I'm sure the size difference here is significant!

```console
$ wc -c bloat.sql
    2202 bloat.sql
$ wc -c bloat.min.sql
    2039 bloat.min.sql
$ # breathtaking!
$ wc -l bloat.sql
      45 bloat.sql
$ wc -l bloat.min.sql
       2 bloat.min.sql
$ # aweinspiring!
$ rm -r $HOME^C
$ # not recommended!
```

Readability is overrated!

## Limitations/Bugs

There are no bugs, just code inputs I didn't anticipate or undesirable behaviors that I don't know about.  That said, there are some possible limitations (I don't care to check them at this time, but assume they are issues):

1. This probably does not handle `COPY` statements.  Due to how our ultra-basic parser works, we do not actually do any deep analysis of contents, so are basically operating on a token level to do our replacements.  As such, since `psql` won't do any such interpolation of its variables in the `STDIN` portion of the block, the generated output would look like raw `:foo` tokens, plus we basically discard any whitespace and use single spaces.  So while writing this out I've definitely convinced myself that that won't work.  So don't do that.  Or do write a patch and give it to me and maybe it'll do that then.

2. ~This will probably not work for any SQL files with `psql` commands in it, so a minimized file re-minimized probably won't work.  I dunno, try it and get back to me; I assume `psql` will not do the double interpolation properly in the first pass, but it might surprise both of us.~  Addendum: I have written psql command and non-string psql var handling. As a consequence, you can pipe valid output from `pgmin` into `pgmin` and it'll be idempotent.  Yay!

3. There are probably parsing quirks that are not accounted for that might need to be, such as scientific notation, `E''` quoted strings, etc.

## Enhancements

While this is already peak software, I'd welcome alternahancements/feedback.  I will probably meh at it, but why not give it a shot?  It might be a half-hearted meh followed by a slow nod and an eventual reluctant merge.

## Author

David Christensen <david.christensen@crunchydata.com>, <david@pgguru.net>
