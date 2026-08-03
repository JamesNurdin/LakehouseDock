WITH base AS (
   SELECT
       s.s_store_name,
       s.s_state,
       sr.sr_net_loss,
       sr.sr_return_quantity,
       cs.cs_ext_sales_price,
       cs.cs_order_number,
       cs.cs_quantity,
       cc.cc_name,
       cc.cc_mkt_id,
       cc.cc_hours,
       cp.cp_department,
       cp.cp_catalog_number,
       wp.wp_type,
       split(cc.cc_hours, ',') AS hours_array
   FROM store s
   FULL OUTER JOIN store_returns sr
       ON s.s_store_sk = sr.sr_store_sk
   LEFT JOIN household_demographics hd_ship
       ON sr.sr_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN catalog_sales cs
       ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN household_demographics hd_bill
       ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   LEFT JOIN web_returns wr
       ON wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
   LEFT JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE cc.cc_mkt_id IN (2, 4, 5)
     AND cp.cp_department = 'Electronics'
     AND s.s_state = 'CA'
     AND wp.wp_type = 'Content'
),

unnested AS (
   SELECT
       b.*,
       hour_val
   FROM base b
   CROSS JOIN UNNEST(b.hours_array) AS t(hour_val)
),

agg AS (
   SELECT
       s_store_name,
       hour_val,
       SUM(cs_ext_sales_price) AS total_sales,
       SUM(sr_net_loss) AS total_loss,
       COUNT(DISTINCT cs_order_number) AS orders_cnt,
       MIN(cs_order_number) AS min_order_number
   FROM unnested
   GROUP BY s_store_name, hour_val
),

final AS (
   SELECT
       a.s_store_name,
       a.hour_val,
       a.total_sales,
       a.total_loss,
       a.orders_cnt,
       SUM(a.total_sales) OVER (PARTITION BY a.s_store_name ORDER BY a.hour_val) AS running_sales,
       a.min_order_number
   FROM agg a
)

SELECT
    f.s_store_name,
    f.hour_val,
    f.total_sales,
    f.total_loss,
    f.orders_cnt,
    f.running_sales,
    (SELECT MAX(cs_ext_sales_price) FROM catalog_sales) AS max_sales_global
FROM final f
WHERE NOT EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_order_number = f.min_order_number
          AND cs2.cs_quantity > 10
      )
  AND f.total_sales > 1000
  AND f.total_loss < 5000
  AND f.orders_cnt >= 5
  AND f.hour_val IS NOT NULL
ORDER BY f.s_store_name ASC, f.hour_val ASC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
