WITH sales_enriched AS (
    -- Store sales enriched with date, promotion and store information
    SELECT
        d_s.d_year,
        d_s.d_month_seq,
        p.p_promo_name,
        s.s_store_name,
        ss.ss_ext_sales_price      AS sales_amount,
        ss.ss_ext_tax              AS tax_amount,
        ss.ss_net_profit           AS net_profit,
        'store'                     AS channel
    FROM store_sales ss
    JOIN date_dim d_s      ON ss.ss_sold_date_sk   = d_s.d_date_sk
    JOIN promotion p       ON ss.ss_promo_sk      = p.p_promo_sk
    JOIN date_dim d_start  ON p.p_start_date_sk   = d_start.d_date_sk
    JOIN date_dim d_end    ON p.p_end_date_sk     = d_end.d_date_sk
    JOIN store s           ON ss.ss_store_sk      = s.s_store_sk
    WHERE d_s.d_date >= DATE '2002-01-01'
      AND d_s.d_date <  DATE '2003-01-01'
      AND d_s.d_date BETWEEN d_start.d_date AND d_end.d_date

    UNION ALL

    -- Web sales enriched with date and promotion information (no store)
    SELECT
        d_s.d_year,
        d_s.d_month_seq,
        p.p_promo_name,
        NULL                     AS s_store_name,
        ws.ws_ext_sales_price    AS sales_amount,
        ws.ws_ext_tax            AS tax_amount,
        ws.ws_net_profit         AS net_profit,
        'web'                    AS channel
    FROM web_sales ws
    JOIN date_dim d_s      ON ws.ws_sold_date_sk   = d_s.d_date_sk
    JOIN promotion p       ON ws.ws_promo_sk       = p.p_promo_sk
    JOIN date_dim d_start  ON p.p_start_date_sk   = d_start.d_date_sk
    JOIN date_dim d_end    ON p.p_end_date_sk     = d_end.d_date_sk
    WHERE d_s.d_date >= DATE '2002-01-01'
      AND d_s.d_date <  DATE '2003-01-01'
      AND d_s.d_date BETWEEN d_start.d_date AND d_end.d_date
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        p_promo_name,
        channel,
        s_store_name,
        SUM(sales_amount) AS total_sales,
        SUM(tax_amount)   AS total_tax,
        SUM(net_profit)   AS total_net_profit
    FROM sales_enriched
    GROUP BY d_year, d_month_seq, p_promo_name, channel, s_store_name
)
SELECT
    d_year,
    d_month_seq,
    COALESCE(s_store_name, 'N/A') AS store_name,
    channel,
    p_promo_name,
    total_sales,
    total_tax,
    total_net_profit,
    ROW_NUMBER() OVER (
        PARTITION BY d_year, d_month_seq, COALESCE(s_store_name, 'N/A'), channel
        ORDER BY total_net_profit DESC
    ) AS promo_rank
FROM aggregated
WHERE total_net_profit > 0
ORDER BY d_year, d_month_seq, store_name, channel, promo_rank
