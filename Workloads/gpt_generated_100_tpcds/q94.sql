WITH catalog_sales_agg AS (
    SELECT
        cs.cs_promo_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_promo_sk, d.d_year
),
catalog_returns_agg AS (
    SELECT
        cs.cs_promo_sk,
        d.d_year,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_promo_sk, d.d_year
),
web_sales_agg AS (
    SELECT
        ws.ws_promo_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_promo_sk, d.d_year
),
web_returns_agg AS (
    SELECT
        ws.ws_promo_sk,
        d.d_year,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_promo_sk, d.d_year
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COALESCE(cs_agg.catalog_net_profit, 0) + COALESCE(ws_agg.web_net_profit, 0)
        - COALESCE(cr_agg.catalog_returns_loss, 0) - COALESCE(wr_agg.web_returns_loss, 0) AS net_profit_after_returns,
    COALESCE(cs_agg.catalog_sales_amount, 0) + COALESCE(ws_agg.web_sales_amount, 0) AS total_sales_amount,
    COALESCE(cs_agg.catalog_orders, 0) + COALESCE(ws_agg.web_orders, 0) AS total_orders,
    COALESCE(cr_agg.catalog_return_orders, 0) + COALESCE(wr_agg.web_return_orders, 0) AS total_return_orders,
    p.p_channel_email,
    p.p_channel_tv
FROM promotion p
LEFT JOIN catalog_sales_agg cs_agg
    ON p.p_promo_sk = cs_agg.cs_promo_sk
LEFT JOIN catalog_returns_agg cr_agg
    ON p.p_promo_sk = cr_agg.cs_promo_sk
LEFT JOIN web_sales_agg ws_agg
    ON p.p_promo_sk = ws_agg.ws_promo_sk
LEFT JOIN web_returns_agg wr_agg
    ON p.p_promo_sk = wr_agg.ws_promo_sk
ORDER BY net_profit_after_returns DESC
LIMIT 10
