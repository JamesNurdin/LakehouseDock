WITH filtered_catalog_pages AS (
    SELECT DISTINCT
        cp_catalog_page_sk,
        cp_description,
        cp_type
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)discount')
      AND cp_type LIKE '%catalog%'
),
catalog_item_sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN filtered_catalog_pages cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY cs.cs_item_sk
    HAVING SUM(cs.cs_net_profit) > 0
),
web_item_sales AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws.ws_item_sk
),
item_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        COALESCE(cis.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(wis.web_net_profit, 0) AS web_net_profit
    FROM item i
    LEFT JOIN catalog_item_sales cis
        ON i.i_item_sk = cis.item_sk
    LEFT JOIN web_item_sales wis
        ON i.i_item_sk = wis.item_sk
    WHERE regexp_like(i.i_product_name, '(?i)Gold')
      AND i.i_brand LIKE 'B%'
),
latest_web_sale AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        MAX(d.d_date) AS latest_sale_date
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk
)
SELECT
    isag.i_item_id,
    isag.i_product_name,
    SUBSTRING(isag.i_product_name FROM 1 FOR 10) AS product_name_prefix,
    isag.i_brand,
    isag.i_category,
    isag.catalog_net_profit,
    isag.web_net_profit,
    lws.latest_sale_date,
    CONCAT('Profit=', CAST(isag.catalog_net_profit + isag.web_net_profit AS VARCHAR)) AS total_profit_str,
    (
        SELECT COUNT(DISTINCT cr.cr_reason_sk)
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = isag.i_item_sk
          AND cr.cr_return_quantity > 0
    ) AS distinct_return_reasons
FROM item_sales_agg isag
JOIN latest_web_sale lws
    ON isag.i_item_sk = lws.item_sk
WHERE (isag.catalog_net_profit + isag.web_net_profit) > 5000
ORDER BY (isag.catalog_net_profit + isag.web_net_profit) DESC
OFFSET 0
LIMIT 100
