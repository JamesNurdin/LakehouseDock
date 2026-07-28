/*
Goal: Compute yearly total net paid and net profit by item category, counting distinct customers who have made a purchase (either in‑store or via catalog) and have at least one web return. The query joins all twelve selected TPC‑DS tables, re‑uses the CUSTOMER and CUSTOMER_DEMOGRAPHICS tables under separate aliases for billing and shipping roles, includes an EXISTS sub‑query, combines two SELECTs with UNION ALL, and limits the result to the top 100 rows.
*/
WITH combined_sales AS (
    -- In‑store sales branch
    SELECT
        d_sold.d_year                         AS year,
        i.i_category                         AS category,
        s.s_store_name                       AS store_name,
        ss.ss_net_paid                       AS net_paid,
        ss.ss_net_profit                     AS net_profit,
        c.c_customer_sk                      AS customer_sk
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returning_customer_sk = c.c_customer_sk
    )

    UNION ALL

    -- Catalog sales branch
    SELECT
        d_sold.d_year                         AS year,
        i.i_category                         AS category,
        CAST(NULL AS varchar)                AS store_name,
        cs.cs_net_paid                       AS net_paid,
        cs.cs_net_profit                     AS net_profit,
        c_bill.c_customer_sk                 AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    -- Join a web return that involves the same item
    JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    -- Resolve the web page creation date to a date_dim row
    JOIN date_dim d_wp_creation
      ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    -- Use the same date_dim row to locate the web site that was open on that date
    JOIN web_site ws
      ON ws.web_open_date_sk = d_wp_creation.d_date_sk
    WHERE wp.wp_type = 'home'
)
SELECT
    u.year,
    u.category,
    COUNT(DISTINCT u.customer_sk) AS distinct_customers,
    SUM(u.net_paid)               AS total_net_paid,
    SUM(u.net_profit)             AS total_net_profit
FROM combined_sales u
GROUP BY u.year, u.category
ORDER BY total_net_profit DESC
LIMIT 100
