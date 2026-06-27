WITH store_month_sales AS (
    SELECT
        s.s_store_name,
        d_sale.d_year,
        d_sale.d_moy,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_ext_discount_amt) AS total_discount,
        sum(ss.ss_net_profit) AS total_net_profit,
        coalesce(sum(sr.sr_return_amt), 0) AS total_returns,
        count(distinct ss.ss_item_sk) AS distinct_items_sold,
        count(distinct ss.ss_promo_sk) AS distinct_promotions_used,
        sum(p.p_cost) AS total_promotion_cost
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d_sale.d_year = 2002
    GROUP BY s.s_store_name, d_sale.d_year, d_sale.d_moy
)
SELECT
    s_store_name,
    d_year,
    d_moy,
    total_sales,
    total_discount,
    total_net_profit,
    total_returns,
    total_sales - total_returns AS net_sales_after_returns,
    distinct_items_sold,
    distinct_promotions_used,
    total_promotion_cost,
    CASE
        WHEN total_sales > 0 THEN total_discount / total_sales
        ELSE NULL
    END AS avg_discount_rate,
    rank() OVER (PARTITION BY d_year, d_moy ORDER BY total_sales DESC) AS sales_rank
FROM store_month_sales
ORDER BY d_year, d_moy, sales_rank
