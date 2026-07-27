WITH store_daily AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_qty,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        CASE
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT'
            ELSE 'LOSS'
        END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND d.d_holiday = 'N'
      AND s.s_state = 'TX'
      AND ss.ss_ext_sales_price > 1000
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
)
SELECT
    sd.s_store_name,
    sd.d_year,
    sd.total_sales,
    sd.total_profit,
    sd.profit_flag,
    RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank,
    sd.total_sales / NULLIF(sd.total_qty, 0) AS avg_price_per_qty
FROM store_daily sd
WHERE sd.total_profit > 0
ORDER BY sd.total_sales DESC
LIMIT 100
