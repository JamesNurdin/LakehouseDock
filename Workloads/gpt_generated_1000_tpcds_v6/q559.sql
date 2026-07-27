WITH distinct_cp AS (
   SELECT DISTINCT cp_catalog_page_sk, cp_description, cp_end_date_sk
   FROM catalog_page
   WHERE cp_type = 'A'
     AND cp_department = 'Electronics'
),

cp_year AS (
   SELECT cp.cp_catalog_page_sk,
          cp.cp_description,
          d.d_year
   FROM distinct_cp cp
   JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
),

sales_agg AS (
   SELECT
       ss.ss_store_sk,
       ss.ss_item_sk,
       d.d_year,
       SUM(ss.ss_net_paid)   AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit
   FROM store_sales ss
   JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i          ON ss.ss_item_sk = i.i_item_sk
   JOIN store s         ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p     ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
     AND s.s_state = 'CA'
     AND i.i_brand = 'Brand#12'
     AND p.p_channel_dmail = 'Y'
     AND p.p_discount_active = 'Y'
     AND ss.ss_ext_sales_price > 1000
   GROUP BY ss.ss_store_sk, ss.ss_item_sk, d.d_year
),

returns_agg AS (
   SELECT
       sr.sr_store_sk,
       sr.sr_item_sk,
       d_ret.d_year,
       SUM(sr.sr_net_loss) AS total_loss
   FROM store_returns sr
   JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN reason r   ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_return_tax > 10
     AND sr.sr_refunded_cash > 100
   GROUP BY sr.sr_store_sk, sr.sr_item_sk, d_ret.d_year
)

SELECT
    s.s_store_name,
    s.s_state,
    i.i_brand,
    i.i_category,
    sa.d_year,
    sa.total_sales,
    COALESCE(ra.total_loss, 0)               AS total_loss,
    (sa.total_profit - COALESCE(ra.total_loss, 0)) AS net_profit,
    cp.cp_description,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY (sa.total_profit - COALESCE(ra.total_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
       ON sa.ss_store_sk = ra.sr_store_sk
      AND sa.ss_item_sk = ra.sr_item_sk
      AND sa.d_year = ra.d_year
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i  ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN cp_year cp
       ON sa.d_year = cp.d_year
WHERE sa.total_sales > 0
ORDER BY sa.d_year DESC, net_profit DESC
LIMIT 100
