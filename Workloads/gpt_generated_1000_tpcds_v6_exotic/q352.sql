WITH catalog_agg AS (
    SELECT
        w.w_warehouse_name   AS warehouse_name,
        w.w_city             AS warehouse_city,
        i.i_category         AS item_category,
        'catalog'            AS source,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit)      AS profit,
        COUNT(*)                  AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND w.w_city = 'Ash Laurel'
      AND i.i_brand = 'BrandX'
      AND cd.cd_purchase_estimate > 5000
      AND EXISTS (
          SELECT 1
          FROM web_site ws
          WHERE ws.web_state = w.w_state
            AND ws.web_open_date_sk = d.d_date_sk
      )
    GROUP BY w.w_warehouse_name, w.w_city, i.i_category
),
store_agg AS (
    SELECT
        w.w_warehouse_name   AS warehouse_name,
        w.w_city             AS warehouse_city,
        i.i_category         AS item_category,
        'store'              AS source,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit)      AS profit,
        COUNT(*)                  AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w              ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r                 ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND w.w_city = 'Oak Ninth'
      AND i.i_brand = 'BrandY'
      AND cd.cd_purchase_estimate BETWEEN 1000 AND 8000
      AND EXISTS (
          SELECT 1
          FROM web_site ws
          WHERE ws.web_state = w.w_state
            AND ws.web_close_date_sk = d.d_date_sk
      )
    GROUP BY w.w_warehouse_name, w.w_city, i.i_category
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY warehouse_name, item_category, source
LIMIT 100
