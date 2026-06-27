WITH store_sales_monthly AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        promotion.p_promo_sk,
        promotion.p_channel_email,
        SUM(store_sales.ss_net_paid) AS store_net_paid,
        SUM(store_sales.ss_net_profit) AS store_net_profit
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    GROUP BY date_dim.d_year, date_dim.d_month_seq, promotion.p_promo_sk, promotion.p_channel_email
),
catalog_sales_monthly AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        promotion.p_promo_sk,
        promotion.p_channel_email,
        SUM(catalog_sales.cs_net_paid) AS catalog_net_paid,
        SUM(catalog_sales.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    GROUP BY date_dim.d_year, date_dim.d_month_seq, promotion.p_promo_sk, promotion.p_channel_email
),
catalog_returns_monthly AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        promotion.p_promo_sk,
        promotion.p_channel_email,
        SUM(catalog_returns.cr_net_loss) AS returns_net_loss,
        SUM(catalog_returns.cr_return_amount) AS returns_amount
    FROM catalog_returns
    JOIN date_dim ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN catalog_sales ON catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
        AND catalog_returns.cr_order_number = catalog_sales.cs_order_number
    JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    GROUP BY date_dim.d_year, date_dim.d_month_seq, promotion.p_promo_sk, promotion.p_channel_email
)
SELECT
    COALESCE(s.d_year, c.d_year, r.d_year) AS year,
    COALESCE(s.d_month_seq, c.d_month_seq, r.d_month_seq) AS month_seq,
    COALESCE(s.p_promo_sk, c.p_promo_sk, r.p_promo_sk) AS promo_sk,
    COALESCE(s.p_channel_email, c.p_channel_email, r.p_channel_email) AS promo_channel_email,
    COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) AS total_net_paid,
    COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) AS total_net_profit,
    COALESCE(r.returns_net_loss, 0) AS total_returns_net_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0)) - COALESCE(r.returns_net_loss, 0) AS net_profit_after_returns
FROM store_sales_monthly s
FULL OUTER JOIN catalog_sales_monthly c
    ON s.d_year = c.d_year
    AND s.d_month_seq = c.d_month_seq
    AND s.p_promo_sk = c.p_promo_sk
FULL OUTER JOIN catalog_returns_monthly r
    ON COALESCE(s.d_year, c.d_year) = r.d_year
    AND COALESCE(s.d_month_seq, c.d_month_seq) = r.d_month_seq
    AND COALESCE(s.p_promo_sk, c.p_promo_sk) = r.p_promo_sk
WHERE COALESCE(s.d_year, c.d_year, r.d_year) = 2020
ORDER BY year, month_seq, promo_sk
