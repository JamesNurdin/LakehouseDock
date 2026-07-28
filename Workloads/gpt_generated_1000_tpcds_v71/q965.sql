WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month = 5
        AND c.c_birth_year = 1990
        AND s.s_state = 'CA'
        AND p.p_channel_email = 'Y'
        AND ss.ss_sales_price > 20.00
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        c.c_salutation = 'Mr.'
        AND s.s_state = 'CA'
        AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
        AND sr.sr_return_quantity > 0
        AND sr.sr_return_amt > 10.00
        AND sr.sr_item_sk IS NOT NULL
    GROUP BY sr.sr_store_sk, sr.sr_customer_sk
),
web_agg AS (
    SELECT
        wp.wp_web_page_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss) AS web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_page wp
    JOIN web_returns wr ON wp.wp_web_page_sk = wr.wr_web_page_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_day = 22
        AND wp.wp_type = 'article'
        AND wp.wp_char_count > 500
        AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
        AND wr.wr_return_quantity > 0
        AND wr.wr_return_amt > 5.00
    GROUP BY wp.wp_web_page_sk, wr.wr_returned_date_sk
)
SELECT
    combined.s_store_id,
    combined.metric_type,
    combined.total_net_paid,
    combined.total_net_profit,
    combined.total_net_loss
FROM (
    SELECT
        s.s_store_id,
        'sales' AS metric_type,
        sa.total_net_paid,
        sa.total_net_profit,
        NULL AS total_net_loss
    FROM sales_agg sa
    JOIN store s ON sa.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        s.s_store_id,
        'returns' AS metric_type,
        NULL AS total_net_paid,
        NULL AS total_net_profit,
        ra.total_net_loss
    FROM returns_agg ra
    JOIN store s ON ra.sr_store_sk = s.s_store_sk
) AS combined
ORDER BY combined.metric_type, combined.s_store_id
LIMIT 100
