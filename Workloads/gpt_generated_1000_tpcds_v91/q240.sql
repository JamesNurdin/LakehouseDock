WITH catalog_fact AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS return_loss,
        d.d_year AS year,
        w.w_warehouse_name AS warehouse_name,
        c.c_customer_id AS customer_id,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        cc.cc_name AS call_center_name,
        cp.cp_department AS department,
        s.s_store_name AS store_name,
        i.inv_quantity_on_hand AS inventory_on_hand,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'PROMO'
      AND w.w_state = 'CA'
      AND ca.ca_country = 'United States'
      AND i.inv_quantity_on_hand > 0
      AND cs.cs_quantity > 0
),
web_fact AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        CAST(NULL AS INTEGER) AS return_quantity,
        CAST(NULL AS DECIMAL(7,2)) AS return_loss,
        d.d_year AS year,
        w.w_warehouse_name AS warehouse_name,
        c.c_customer_id AS customer_id,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        CAST(NULL AS VARCHAR) AS call_center_name,
        CAST(NULL AS VARCHAR) AS department,
        s.s_store_name AS store_name,
        i.inv_quantity_on_hand AS inventory_on_hand,
        'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND ws_site.web_state = 'CA'
      AND w.w_state = 'CA'
      AND ca.ca_country = 'United States'
      AND i.inv_quantity_on_hand > 0
      AND ws.ws_quantity > 0
      AND ws.ws_net_profit > 0
),
combined_fact AS (
    SELECT * FROM catalog_fact
    UNION DISTINCT
    SELECT * FROM web_fact
),
agg AS (
    SELECT
        year,
        warehouse_name,
        store_name,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit,
        SUM(COALESCE(return_loss, 0)) AS total_return_loss,
        SUM(COALESCE(return_quantity, 0)) AS total_return_quantity
    FROM combined_fact
    GROUP BY ROLLUP (year, warehouse_name, store_name)
)
SELECT
    year,
    warehouse_name,
    store_name,
    total_quantity,
    total_net_profit,
    total_return_loss,
    total_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY year ORDER BY warehouse_name ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_profit
FROM agg
WHERE year IS NOT NULL
ORDER BY year, profit_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
