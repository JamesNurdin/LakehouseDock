WITH sales_data AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        s.channel,
        SUM(s.amount) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        SUM(s.discount_amt) AS total_discount,
        SUM(s.quantity) AS total_quantity,
        COUNT(DISTINCT s.customer_sk) AS distinct_customers,
        COUNT(*) AS sales_cnt
    FROM (
        SELECT cs.cs_sold_date_sk AS date_sk,
               'Catalog' AS channel,
               cs.cs_ext_sales_price AS amount,
               cs.cs_net_profit AS net_profit,
               cs.cs_ext_discount_amt AS discount_amt,
               cs.cs_quantity AS quantity,
               cs.cs_bill_customer_sk AS customer_sk
        FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_sold_date_sk,
               'Store',
               ss.ss_ext_sales_price,
               ss.ss_net_profit,
               ss.ss_ext_discount_amt,
               ss.ss_quantity,
               ss.ss_customer_sk
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_sold_date_sk,
               'Web',
               ws.ws_ext_sales_price,
               ws.ws_net_profit,
               ws.ws_ext_discount_amt,
               ws.ws_quantity,
               ws.ws_bill_customer_sk
        FROM web_sales ws
    ) s
    JOIN date_dim d ON d.d_date_sk = s.date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, s.channel
),
returns_data AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        r.channel,
        SUM(r.amount) AS total_returns,
        SUM(r.net_loss) AS total_loss,
        SUM(r.quantity) AS total_return_quantity,
        COUNT(*) AS return_cnt
    FROM (
        SELECT cr.cr_returned_date_sk AS date_sk,
               'Catalog' AS channel,
               cr.cr_return_amount AS amount,
               cr.cr_net_loss AS net_loss,
               cr.cr_return_quantity AS quantity
        FROM catalog_returns cr
        UNION ALL
        SELECT sr.sr_returned_date_sk,
               'Store',
               sr.sr_return_amt,
               sr.sr_net_loss,
               sr.sr_return_quantity
        FROM store_returns sr
        UNION ALL
        SELECT wr.wr_returned_date_sk,
               'Web',
               wr.wr_return_amt,
               wr.wr_net_loss,
               wr.wr_return_quantity
        FROM web_returns wr
    ) r
    JOIN date_dim d ON d.d_date_sk = r.date_sk
    GROUP BY d.d_year, d.d_month_seq, r.channel
),
combined AS (
    SELECT 
        COALESCE(s.d_year, r.d_year) AS year,
        COALESCE(s.d_month_seq, r.d_month_seq) AS month_seq,
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(s.total_discount, 0) AS total_discount,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.distinct_customers, 0) AS distinct_customers,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_loss, 0) AS total_loss,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        CASE 
            WHEN COALESCE(s.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) / NULLIF(COALESCE(s.total_sales, 0), 0)
        END AS net_sales_ratio,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(s.channel, r.channel) ORDER BY COALESCE(s.d_year, r.d_year), COALESCE(s.d_month_seq, r.d_month_seq)) AS seq_in_channel
    FROM sales_data s
    FULL OUTER JOIN returns_data r
        ON s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.channel = r.channel
),
final AS (
    SELECT 
        c.year,
        c.month_seq,
        c.channel,
        c.total_sales,
        c.total_returns,
        c.total_profit,
        c.total_loss,
        c.total_discount,
        c.total_quantity,
        c.distinct_customers,
        c.net_sales_ratio,
        c.seq_in_channel,
        CONCAT(c.channel, ' ', CAST(c.year AS VARCHAR), '-', LPAD(CAST(c.month_seq AS VARCHAR), 2, '0')) AS label,
        CASE 
            WHEN c.total_sales = 0 THEN 'No Sales'
            WHEN c.net_sales_ratio > 0.8 THEN 'Excellent'
            WHEN c.net_sales_ratio > 0.5 THEN 'Good'
            ELSE 'Weak'
        END AS sales_status,
        LAG(c.net_sales_ratio) OVER (PARTITION BY c.channel ORDER BY c.year, c.month_seq) AS prev_month_ratio,
        AVG(c.net_sales_ratio) OVER (PARTITION BY c.channel ORDER BY c.year, c.month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_ratio,
        (
            SELECT COUNT(DISTINCT sp.promo_sk)
            FROM (
                SELECT cs.cs_promo_sk AS promo_sk, cs.cs_sold_date_sk AS date_sk, 'Catalog' AS channel
                FROM catalog_sales cs
                UNION ALL
                SELECT ss.ss_promo_sk, ss.ss_sold_date_sk, 'Store'
                FROM store_sales ss
                UNION ALL
                SELECT ws.ws_promo_sk, ws.ws_sold_date_sk, 'Web'
                FROM web_sales ws
            ) sp
            JOIN date_dim d ON d.d_date_sk = sp.date_sk
            WHERE d.d_year = c.year
              AND d.d_month_seq = c.month_seq
              AND sp.channel = c.channel
              AND sp.promo_sk IS NOT NULL
        ) AS promo_cnt
    FROM combined c
)
SELECT *
FROM final
WHERE (net_sales_ratio > 0.5 OR prev_month_ratio IS NULL)
ORDER BY channel, year, month_seq
