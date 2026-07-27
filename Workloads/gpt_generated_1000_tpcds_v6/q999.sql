WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(wr.wr_net_loss) AS total_return_loss,
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss)) AS overall_profit
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND cs.cs_coupon_amt > 1000
      AND ss.ss_quantity >= 2
      AND wr.wr_return_quantity <= 30
      AND p.p_channel_dmail = 'Y'
      AND p.p_discount_active = 'Y'
    GROUP BY ROLLUP (p.p_promo_id, hd.hd_income_band_sk)
)
SELECT
    p_promo_id,
    hd_income_band_sk,
    catalog_net_paid,
    store_net_paid,
    total_return_loss,
    overall_profit,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY overall_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY p_promo_id, hd_income_band_sk
