WITH catalog_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'Catalog' AS channel,
        promo.p_promo_id AS promo_id
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        CROSS JOIN LATERAL (
            SELECT p.p_promo_id
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
            ORDER BY p.p_start_date_sk DESC
            LIMIT 1
        ) promo
    WHERE
        i.i_current_price > 50
        AND cs.cs_quantity > 0
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        i.i_item_id,
        i.i_item_desc,
        promo.p_promo_id
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'Web' AS channel,
        NULL AS promo_id
    FROM
        web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        i.i_current_price > 50
        AND ws.ws_quantity > 0
        AND w.web_manager = 'James Austin'
    GROUP BY
        i.i_item_id,
        i.i_item_desc
)
SELECT
    item_id,
    item_desc,
    total_sales,
    channel,
    promo_id
FROM catalog_agg
UNION ALL
SELECT
    item_id,
    item_desc,
    total_sales,
    channel,
    promo_id
FROM web_agg
ORDER BY total_sales DESC, channel
LIMIT 100
