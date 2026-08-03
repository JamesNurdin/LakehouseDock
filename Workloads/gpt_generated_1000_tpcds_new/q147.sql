WITH ss_branch AS (
   SELECT
       ss.ss_ticket_number AS ss_ticket_number,
       ss.ss_sold_date_sk AS ss_sold_date_sk,
       ss.ss_item_sk AS ss_item_sk,
       ss.ss_customer_sk AS ss_customer_sk,
       ss.ss_quantity AS ss_quantity,
       ss.ss_ext_sales_price AS ss_ext_sales_price,
       ss.ss_net_profit AS ss_net_profit,
       sr.sr_return_quantity AS sr_return_quantity,
       sr.sr_return_amt AS sr_return_amt,
       sr.sr_net_loss AS sr_net_loss,
       i.i_item_id AS i_item_id,
       i.i_product_name AS i_product_name,
       c.c_customer_sk AS c_customer_sk,
       c.c_customer_id AS c_customer_id,
       c.c_first_name AS c_first_name,
       c.c_last_name AS c_last_name,
       wp.wp_url AS wp_url
   FROM store_sales ss
   FULL OUTER JOIN store_returns sr
       ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp
       ON c.c_customer_sk = wp.wp_customer_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451820
     AND (ss.ss_quantity > 1 OR sr.sr_return_quantity > 0)
),
cs_branch AS (
   SELECT
       cs.cs_order_number AS cs_order_number,
       cs.cs_sold_date_sk AS cs_sold_date_sk,
       cs.cs_item_sk AS cs_item_sk,
       cs.cs_bill_customer_sk AS cs_bill_customer_sk,
       cs.cs_ship_customer_sk AS cs_ship_customer_sk,
       cs.cs_quantity AS cs_quantity,
       cs.cs_ext_sales_price AS cs_ext_sales_price,
       cs.cs_net_profit AS cs_net_profit,
       cs.cs_call_center_sk AS cs_call_center_sk,
       i.i_item_id AS i_item_id,
       i.i_product_name AS i_product_name,
       c.c_customer_sk AS c_customer_sk,
       c.c_customer_id AS c_customer_id,
       c.c_first_name AS c_first_name,
       c.c_last_name AS c_last_name,
       cc.cc_name AS cc_name,
       cp.cp_department AS cp_department,
       w.w_warehouse_id AS w_warehouse_id,
       w.w_city AS w_city
   FROM catalog_sales cs
   LEFT JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   LEFT JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451820
     AND cs.cs_quantity > 1
     AND cs.cs_ext_tax > 10
)
SELECT
    COALESCE(ss.c_customer_id, cs.c_customer_id) AS customer_id,
    COALESCE(ss.c_first_name, cs.c_first_name) AS first_name,
    COALESCE(ss.c_last_name, cs.c_last_name) AS last_name,
    COALESCE(ss.i_item_id, cs.i_item_id) AS item_id,
    COALESCE(ss.i_product_name, cs.i_product_name) AS product_name,
    COALESCE(ss.ss_quantity, cs.cs_quantity) AS quantity,
    COALESCE(ss.ss_ext_sales_price, cs.cs_ext_sales_price) AS sales_amount,
    COALESCE(ss.ss_net_profit, cs.cs_net_profit) AS net_profit,
    COALESCE(ss.wp_url, '') AS web_page_url,
    COALESCE(cs.cc_name, '') AS call_center_name,
    COALESCE(cs.cp_department, '') AS catalog_department,
    COALESCE(cs.w_warehouse_id, '') AS warehouse_id,
    CASE
        WHEN ss.sr_return_quantity IS NOT NULL THEN 'Return'
        WHEN cs.cc_name IS NOT NULL THEN 'Catalog'
        ELSE 'Store'
    END AS sales_channel,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(ss.c_customer_id, cs.c_customer_id)
        ORDER BY COALESCE(ss.ss_net_profit, cs.cs_net_profit) DESC
    ) AS rn_customer,
    RANK() OVER (
        ORDER BY COALESCE(ss.ss_net_profit, cs.cs_net_profit) DESC
    ) AS overall_rank
FROM ss_branch ss
FULL OUTER JOIN cs_branch cs
   ON ss.c_customer_sk = cs.c_customer_sk
WHERE COALESCE(ss.ss_net_profit, cs.cs_net_profit) > 0
  AND COALESCE(ss.ss_quantity, cs.cs_quantity) >= 2
  AND COALESCE(ss.sr_return_quantity, 0) = 0
ORDER BY overall_rank
LIMIT 100
