WITH agg_cs AS (
    SELECT cs.cs_item_sk,
           SUM(cs.cs_net_paid) AS total_cs_paid
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
agg_ws AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_net_paid) AS total_ws_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
union_sales AS (
    SELECT cs_item_sk AS i_item_sk, total_cs_paid AS total_paid
    FROM agg_cs
    UNION DISTINCT
    SELECT ws_item_sk AS i_item_sk, total_ws_paid AS total_paid
    FROM agg_ws
),
returns_items AS (
    SELECT sr.sr_item_sk AS i_item_sk
    FROM store_returns sr
    INTERSECT
    SELECT wr.wr_item_sk
    FROM web_returns wr
),
filtered_sales AS (
    SELECT us.i_item_sk,
           us.total_paid
    FROM union_sales us
    WHERE us.i_item_sk NOT IN (
        SELECT sr2.sr_item_sk
        FROM store_returns sr2
        WHERE sr2.sr_net_loss > 1000
    )
),
joined_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_color,
        i.i_current_price,
        fs.total_paid,
        cc.cc_name,
        cc.cc_county,
        cp.cp_description,
        w.w_city,
        w.w_state,
        c.c_first_name,
        c.c_last_name,
        ws.ws_quantity,
        ws.ws_net_profit,
        sr.sr_item_sk AS sr_key,
        wr.wr_item_sk AS wr_key
    FROM filtered_sales fs
    JOIN item i ON i.i_item_sk = fs.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE w.w_state = 'CA'
      AND cc.cc_county = 'Bronx County'
      AND i.i_current_price BETWEEN 10 AND 100
      AND ws.ws_quantity > 5
      AND i.i_item_sk IN (SELECT i_item_sk FROM returns_items)
),
ranked AS (
    SELECT
        i_item_id,
        i_product_name,
        i_category,
        CASE WHEN i_color = 'Red' THEN 'RED' ELSE i_color END AS normalized_color,
        total_paid,
        cc_name,
        cp_description,
        w_city,
        c_first_name,
        c_last_name,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_paid DESC) AS rn
    FROM joined_data
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    normalized_color,
    total_paid,
    cc_name,
    cp_description,
    w_city,
    c_first_name,
    c_last_name,
    ws_net_profit
FROM ranked
WHERE rn <= 3
ORDER BY total_paid DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
