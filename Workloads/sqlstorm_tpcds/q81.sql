WITH returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number, sr.sr_item_sk, sr.sr_store_sk
),
sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        s.s_state AS state,
        d.d_year AS sales_year,
        i.i_category AS category,
        cd.cd_gender AS gender,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        COALESCE(SUM(r.total_return_quantity), 0) AS total_returns,
        COALESCE(SUM(r.total_return_loss), 0) AS total_returns_loss
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN returns_agg r
        ON ss.ss_ticket_number = r.sr_ticket_number
        AND ss.ss_item_sk = r.sr_item_sk
        AND ss.ss_store_sk = r.sr_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_name,
        s.s_state,
        d.d_year,
        i.i_category,
        cd.cd_gender,
        p.p_promo_name
    HAVING SUM(ss.ss_ext_sales_price) > 100000
)
SELECT
    store_name,
    sales_year,
    category,
    gender,
    promo_name,
    total_sales,
    total_quantity,
    total_returns,
    CASE WHEN total_quantity > 0 THEN total_returns / total_quantity END AS return_rate,
    total_profit - total_returns_loss AS net_profit,
    CASE WHEN total_sales > 0 THEN total_discount / total_sales END AS avg_discount_rate,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY sales_year, store_name ORDER BY (total_profit - total_returns_loss) DESC) AS profit_rank
FROM sales_agg
ORDER BY sales_year, store_name, net_profit DESC
LIMIT 50
