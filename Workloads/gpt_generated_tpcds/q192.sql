WITH catalog_sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cr.cr_net_loss,
        p.p_promo_id,
        p.p_promo_name,
        cp.cp_department AS department
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        wr.wr_net_loss,
        p.p_promo_id,
        p.p_promo_name,
        CAST(NULL AS varchar) AS department
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT
        p_promo_id,
        p_promo_name,
        department,
        cs_net_profit AS sales_profit,
        cr_net_loss AS returns_loss
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        p_promo_id,
        p_promo_name,
        department,
        ws_net_profit AS sales_profit,
        wr_net_loss AS returns_loss
    FROM web_sales_agg
)
SELECT
    p_promo_id,
    p_promo_name,
    department,
    SUM(sales_profit) AS total_sales_profit,
    SUM(returns_loss) AS total_returns_loss,
    SUM(sales_profit) - SUM(returns_loss) AS net_profit
FROM combined
GROUP BY p_promo_id, p_promo_name, department
ORDER BY net_profit DESC
LIMIT 20
