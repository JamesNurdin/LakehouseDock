WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        p.p_promo_sk AS promo_sk,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_email,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(CASE WHEN ss.ss_ext_list_price <> 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_list_price END) AS avg_discount_ratio,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month IN (4, 12)
      AND p.p_discount_active = 'Y'
      AND i.i_class = 'Electronics'
    GROUP BY i.i_category, p.p_promo_sk, p.p_channel_tv, p.p_channel_radio, p.p_channel_email
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        p.p_promo_sk AS promo_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month IN (4, 12)
      AND i.i_class = 'Electronics'
    GROUP BY i.i_category, p.p_promo_sk
)
SELECT
    s.category,
    s.p_channel_tv,
    s.p_channel_radio,
    s.p_channel_email,
    s.total_sales,
    s.total_profit,
    s.avg_discount_ratio,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_revenue,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.category = r.category
   AND s.promo_sk = r.promo_sk
ORDER BY net_revenue DESC
LIMIT 100
