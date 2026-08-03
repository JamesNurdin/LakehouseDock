WITH page_words AS (
   SELECT cp.cp_catalog_page_sk,
          word
   FROM catalog_page cp
   CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(word)
   WHERE regexp_like(word, '^[A-Z]{3}$')
),
store_agg AS (
   SELECT s.s_store_id,
          s.s_store_name,
          s.s_city,
          s.s_state,
          s.s_market_id,
          SUM(ss.ss_net_profit) AS total_net_profit,
          COUNT(DISTINCT ss.ss_hdemo_sk) AS distinct_demo_count
   FROM store_sales ss
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE s.s_state = 'WA'
     AND s.s_market_id = (
         SELECT max(s_market_id)
         FROM store
         WHERE s_state = 'WA'
     )
     AND regexp_like(s.s_city, '^A.*')
   GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state, s.s_market_id
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.s_state,
    sa.s_market_id,
    sa.total_net_profit,
    sa.distinct_demo_count,
    regexp_extract(sa.s_city, '^(.{3})', 1) AS city_prefix,
    concat(sa.s_city, ', ', sa.s_state) AS location,
    pw.word
FROM store_agg sa
LEFT JOIN page_words pw
  ON pw.cp_catalog_page_sk = (
        SELECT cs.cs_catalog_page_sk
        FROM catalog_sales cs
        WHERE cs.cs_order_number = (
              SELECT cr.cr_order_number
              FROM catalog_returns cr
              WHERE cr.cr_returned_date_sk = (
                  SELECT max(cr_returned_date_sk) FROM catalog_returns
              )
              LIMIT 1
        )
        LIMIT 1
     )
ORDER BY sa.total_net_profit DESC
LIMIT 100
