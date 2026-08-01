WITH catalog_branch AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        w.w_warehouse_name,
        cs.cs_sold_date_sk            AS sold_date_sk,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        lr.item_return_total,
        (SELECT MAX(sr_return_amt_inc_tax)
         FROM store_returns sr
         WHERE sr.sr_item_sk = i.i_item_sk)                               AS max_return_inc_tax,
        (SELECT COUNT(*)
         FROM store_returns sr2
         WHERE sr2.sr_customer_sk = c.c_customer_sk)                      AS cust_return_count
    FROM catalog_sales cs
    RIGHT OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN LATERAL (
        SELECT SUM(sr_return_amt) AS item_return_total
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
    ) AS lr ON TRUE
    WHERE w.w_gmt_offset = -5.00
      AND i.i_brand = 'Brand#12'
      AND c.c_birth_country = 'JAPAN'
      AND t.t_hour BETWEEN 8 AND 12
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cp.cp_type = 'PROMO'
      AND cs.cs_item_sk NOT IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red')
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = cs.cs_item_sk
            AND ws.ws_net_profit > 500
      )
),
web_branch AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        w.w_warehouse_name,
        ws.ws_sold_date_sk           AS sold_date_sk,
        ws.ws_net_profit,
        CASE WHEN ws.ws_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        lr.item_return_total,
        (SELECT MAX(sr_return_amt_inc_tax)
         FROM store_returns sr
         WHERE sr.sr_item_sk = i.i_item_sk)                               AS max_return_inc_tax,
        (SELECT COUNT(*)
         FROM store_returns sr2
         WHERE sr2.sr_customer_sk = c.c_customer_sk)                      AS cust_return_count
    FROM web_sales ws
    RIGHT OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN LATERAL (
        SELECT SUM(sr_return_amt) AS item_return_total
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
    ) AS lr ON TRUE
    WHERE w.w_gmt_offset = -5.00
      AND i.i_brand = 'Brand#12'
      AND c.c_birth_country = 'JAPAN'
      AND t.t_hour BETWEEN 8 AND 12
      AND ws.ws_quantity > 5
      AND ws.ws_net_profit > 0
      AND ws.ws_item_sk NOT IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red')
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = ws.ws_item_sk
            AND cs2.cs_net_profit > 500
      )
)
SELECT *
FROM (
    SELECT * FROM catalog_branch
    UNION
    SELECT * FROM web_branch
) AS u
ORDER BY profit_rank ASC, max_return_inc_tax DESC
OFFSET 0 LIMIT 100
