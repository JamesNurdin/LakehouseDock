/*
Goal: Identify high‑profit orders from 2001 across catalog, web and store channels, enrich them with customer and inventory info, exclude any orders that were later returned, rank the results within each channel, and return the top 100 rows.
*/
WITH
-- Catalog channel sales enriched with dimensions and possible return reason
cat_sales AS (
    SELECT
        cs.cs_order_number                     AS order_id,
        d.d_year                               AS year,
        cp.cp_department                       AS department,
        cs.cs_net_profit                       AS profit,
        cs.cs_quantity                         AS quantity,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        COALESCE(r.r_reason_desc, 'No Return') AS reason_desc,
        inv.inv_quantity_on_hand               AS inventory_on_hand,
        'Catalog'                              AS source
    FROM catalog_sales cs
    JOIN date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp   ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r          ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv    ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Electronics'
      AND cd.cd_gender = 'M'
      AND cs.cs_quantity > 1
),

-- Web channel sales enriched with dimensions and inventory info
web_sales_cte AS (
    SELECT
        ws.ws_order_number                     AS order_id,
        d.d_year                               AS year,
        wp.wp_type                             AS department,
        ws.ws_net_profit                       AS profit,
        ws.ws_quantity                         AS quantity,
        CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        'N/A'                                  AS reason_desc,
        inv.inv_quantity_on_hand               AS inventory_on_hand,
        'Web'                                  AS source
    FROM web_sales ws
    JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv    ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'HOME'
      AND cd.cd_gender = 'M'
      AND ws.ws_quantity > 1
),

-- Store channel sales enriched with dimensions, possible return reason and inventory info
store_sales_cte AS (
    SELECT
        ss.ss_ticket_number                    AS order_id,
        d.d_year                               AS year,
        'Store'                                AS department,
        ss.ss_net_profit                       AS profit,
        ss.ss_quantity                         AS quantity,
        CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        COALESCE(r.r_reason_desc, 'No Return') AS reason_desc,
        inv.inv_quantity_on_hand               AS inventory_on_hand,
        'Store'                                AS source
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r          ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv    ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND ss.ss_quantity > 0
),

-- Union of all channel sales (deduplicated)
all_sales AS (
    SELECT * FROM cat_sales
    UNION DISTINCT
    SELECT * FROM web_sales_cte
    UNION DISTINCT
    SELECT * FROM store_sales_cte
),

-- Set of order identifiers that have any return (catalog or store)
return_orders AS (
    SELECT cr.cr_order_number AS order_id FROM catalog_returns cr
    UNION
    SELECT sr.sr_ticket_number AS order_id FROM store_returns sr
),

-- Remove returned orders using EXCEPT (same column list for both sides)
filtered_sales AS (
    SELECT * FROM all_sales
    EXCEPT
    SELECT * FROM all_sales
    WHERE order_id IN (SELECT order_id FROM return_orders)
)
SELECT
    order_id,
    year,
    department,
    profit,
    quantity,
    profit_flag,
    reason_desc,
    inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY profit DESC) AS rn,
    RANK()        OVER (PARTITION BY department ORDER BY profit DESC) AS rnk
FROM filtered_sales
ORDER BY profit DESC, department
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
