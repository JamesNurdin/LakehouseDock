WITH sales_agg AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        d_sold.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit)      AS total_profit,
        SUM(cs.cs_quantity)        AS total_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_moy IN (1, 5, 12)               -- only Jan, May, Dec sales
      AND d_sold.d_holiday = 'N'                  -- exclude holiday sales days
    GROUP BY cs.cs_promo_sk, cs.cs_bill_cdemo_sk, d_sold.d_year
)
SELECT
    p.p_promo_name,
    sa.d_year,
    cd.cd_gender,
    sa.total_sales,
    sa.total_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN promotion p               ON sa.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_start          ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end            ON p.p_end_date_sk   = d_end.d_date_sk
JOIN customer_demographics cd  ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr          ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_return         ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE p.p_channel_radio = 'N'               -- radio channel not used
  AND p.p_cost > 500.00                     -- expensive promotions only
  AND d_return.d_holiday = 'N'              -- returns on non‑holiday days
  AND cd.cd_gender = 'M'                    -- male customers
GROUP BY p.p_promo_name, sa.d_year, cd.cd_gender, sa.total_sales, sa.total_profit
ORDER BY sa.d_year DESC, profit_rank ASC
LIMIT 100
