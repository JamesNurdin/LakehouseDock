WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        cp.cp_department,
        i.i_brand,
        i.i_units,
        i.i_container,
        cs.cs_order_number,
        cs.cs_net_paid,
        ws.ws_order_number,
        ws.ws_net_paid,
        sr.sr_return_amt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_units = 'Lb'
      AND i.i_container = 'Unknown'
      AND cp.cp_department = 'Sports'
      AND s.s_state = 'CA'
      AND sr.sr_return_ship_cost > 100
      AND wp.wp_autogen_flag = 'N'
      AND EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND sr2.sr_return_amt > 500
      )
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    cp_department,
    i_brand,
    i_units,
    i_container,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    AVG(sr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws_order_number) AS web_order_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
FROM base
GROUP BY
    s_store_id,
    s_store_name,
    s_state,
    cp_department,
    i_brand,
    i_units,
    i_container
ORDER BY total_web_sales DESC
LIMIT 100
