WITH
  sampled_catalog AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),

  joined_data AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid_inc_ship,
      cs.cs_net_profit,
      cp.cp_department,
      cp.cp_type,
      p.p_promo_name,
      p.p_discount_active,
      ca.ca_state,
      hd.hd_income_band_sk,
      CASE 
        WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
        WHEN cs.cs_net_profit BETWEEN 0 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS profit_category
    FROM sampled_catalog cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  ),

  store_promo_full AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      p.p_promo_name,
      ca.ca_state,
      hd.hd_income_band_sk,
      CASE 
        WHEN ss.ss_net_profit > 500 THEN 'GOOD'
        ELSE 'POOR'
      END AS store_profit_flag
    FROM store_sales ss
    FULL OUTER JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
  ),

  order_intersect AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
    INTERSECT
    SELECT ss_ticket_number FROM store_sales
  ),

  agg_by_category AS (
    SELECT
      profit_category,
      MIN(cs_sold_date_sk) AS min_sold_date_sk,
      COUNT(DISTINCT cs_order_number) AS distinct_orders,
      SUM(DISTINCT cs_quantity) AS distinct_quantity_sum,
      AVG(cs_net_paid_inc_ship) AS avg_net_paid_inc_ship
    FROM joined_data
    WHERE cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND cs_quantity > 1
      AND cs_net_paid_inc_ship > 0
      AND p_discount_active = 'Y'
      AND ca_state IN ('CA','TX','NY')
      AND hd_income_band_sk IS NOT NULL
      AND cp_type = 'STANDARD'
    GROUP BY profit_category
  ),

  final AS (
    SELECT
      a.profit_category,
      a.distinct_orders,
      a.distinct_quantity_sum,
      a.avg_net_paid_inc_ship,
      (SELECT SUM(wr_return_amt)
         FROM web_returns wr
        WHERE wr.wr_returned_date_sk = a.min_sold_date_sk) AS returns_on_same_date,
      (SELECT COUNT(DISTINCT spf.ss_ticket_number)
         FROM store_promo_full spf
        WHERE spf.store_profit_flag = 'GOOD') AS good_store_sales_cnt,
      (SELECT SUM(DISTINCT spf.ss_net_paid)
         FROM store_promo_full spf
        WHERE spf.store_profit_flag = 'GOOD') AS sum_distinct_good_net_paid,
      (SELECT COUNT(*) FROM order_intersect) AS intersect_order_cnt
    FROM agg_by_category a
    WHERE a.avg_net_paid_inc_ship > 100
  )

SELECT *
FROM final
ORDER BY distinct_orders DESC, profit_category
LIMIT 100
