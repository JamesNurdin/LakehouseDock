WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 1000
)
SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month,
    c.c_customer_id,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_promo_name,
    ws.web_name,
    SUM(sa.cs_net_paid) AS total_net_paid,
    SUM(sa.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT sa.cs_order_number) AS order_cnt,
    RANK() OVER (ORDER BY SUM(sa.cs_net_paid) DESC) AS revenue_rank,
    SUM(SUM(sa.cs_net_paid)) OVER (PARTITION BY d_sold.d_year) AS year_cumulative_paid
FROM sales_agg sa
JOIN date_dim d_sold
    ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON sa.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c
    ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_returns wr
    ON sa.cs_order_number = wr.wr_order_number
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON wp.wp_creation_date_sk = ws.web_open_date_sk
WHERE cd.cd_credit_rating = 'Good'
  AND d_sold.d_year BETWEEN 1999 AND 2001
  AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_return_amt > 100
          AND wr2.wr_returning_customer_sk = c.c_customer_sk
      )
GROUP BY
    d_sold.d_year,
    d_ship.d_month_seq,
    c.c_customer_id,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_promo_name,
    ws.web_name
ORDER BY total_net_paid DESC
LIMIT 100
