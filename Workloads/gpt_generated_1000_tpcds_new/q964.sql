WITH cs_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        p.p_channel_catalog,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE regexp_like(p.p_channel_catalog, '^Y')
      AND i.i_item_desc LIKE '%special%'
      AND regexp_extract(i.i_item_desc, '(\\w+)-\\w+', 1) IS NOT NULL
    GROUP BY CUBE(i.i_category, i.i_brand, p.p_channel_catalog)
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
cs_window AS (
    SELECT
        i_category,
        i_brand,
        p_channel_catalog,
        total_sales,
        total_profit,
        order_cnt,
        SUM(total_sales) OVER (PARTITION BY i_category ORDER BY i_brand ROWS UNBOUNDED PRECEDING) AS running_sales
    FROM cs_agg
),
ws_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        p.p_channel_email AS p_channel_catalog,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE p.p_channel_email LIKE '%Y%'
      AND i.i_item_desc LIKE '%promo%'
      AND regexp_like(i.i_item_desc, '^.*[0-9]{4}.*$')
    GROUP BY CUBE(i.i_category, i.i_brand, p.p_channel_email)
    HAVING SUM(ws.ws_ext_sales_price) > 15000
),
ws_window AS (
    SELECT
        i_category,
        i_brand,
        p_channel_catalog,
        total_sales,
        total_profit,
        order_cnt,
        SUM(total_sales) OVER (PARTITION BY i_category ORDER BY i_brand ROWS UNBOUNDED PRECEDING) AS running_sales
    FROM ws_agg
)
SELECT *
FROM (
    SELECT * FROM cs_window
    UNION
    SELECT * FROM ws_window
) combined
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
