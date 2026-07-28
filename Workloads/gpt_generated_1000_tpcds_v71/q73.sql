WITH distinct_items AS (
    SELECT DISTINCT i.i_item_sk,
                    i.i_category,
                    i.i_brand
    FROM item i
    WHERE i.i_brand = 'Brand#12'
)
SELECT
    w.w_state,
    di.i_category,
    SUM(cs.cs_net_paid)                     AS total_net_paid,
    AVG(cs.cs_ext_ship_cost)                AS avg_ship_cost,
    COUNT(DISTINCT cs.cs_order_number)      AS distinct_orders,
    MIN(cs.cs_sold_date_sk)                 AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk)                 AS max_sold_date_sk
FROM catalog_sales cs
JOIN distinct_items di
    ON cs.cs_item_sk = di.i_item_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
  AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = cs.cs_item_sk
            AND wr.wr_order_number = cs.cs_order_number
      )
  AND cp.cp_department = 'Electronics'
  AND w.w_state = 'CA'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_income_band_sk = 3
  AND cs.cs_sold_date_sk BETWEEN 2450816 AND 2450835
GROUP BY GROUPING SETS (
    (w.w_state, di.i_category),
    (w.w_state),
    (di.i_category),
    ()
)
ORDER BY w.w_state ASC,
         di.i_category ASC,
         total_net_paid DESC
LIMIT 100
