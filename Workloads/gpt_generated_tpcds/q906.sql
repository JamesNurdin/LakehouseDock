/*
   Monthly net profit per store and product category, adjusted for returns.
   This query aggregates sales and returns, then combines them to show the
   net profit after accounting for returned items.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year        AS year,
        d.d_month_seq   AS month_seq,
        i.i_category    AS category,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_net_profit)       AS total_net_profit,
        sum(ss.ss_ext_discount_amt) AS total_discount,
        count(DISTINCT ss.ss_promo_sk) AS promo_count
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year        AS year,
        d.d_month_seq   AS month_seq,
        i.i_category    AS category,
        sum(sr.sr_net_loss) AS total_return_loss,
        count(*)            AS return_count
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.store_name,
    s.year,
    s.month_seq,
    s.category,
    s.total_sales,
    s.total_net_profit,
    s.total_discount,
    s.promo_count,
    coalesce(r.total_return_loss, 0) AS total_return_loss,
    coalesce(r.return_count, 0)      AS return_count,
    (s.total_net_profit - coalesce(r.total_return_loss, 0)) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.store_name = r.store_name
   AND s.year       = r.year
   AND s.month_seq  = r.month_seq
   AND s.category   = r.category
ORDER BY net_profit_after_returns DESC
LIMIT 20
