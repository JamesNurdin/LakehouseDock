WITH sales_summary AS (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        p.p_channel_tv,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
        SUM(ss.ss_quantity) AS total_quantity,
        CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0
             ELSE CAST(SUM(COALESCE(sr.sr_return_quantity, 0)) AS DOUBLE) / CAST(SUM(ss.ss_quantity) AS DOUBLE)
        END AS return_qty_rate,
        CASE WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
             ELSE CAST(SUM(COALESCE(sr.sr_return_amt, 0)) AS DOUBLE) / CAST(SUM(ss.ss_ext_sales_price) AS DOUBLE)
        END AS return_amt_rate
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_store_sk = sr.sr_store_sk
    WHERE d.d_year = 2000
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, s.s_state, i.i_category, p.p_channel_tv, cd.cd_gender, hd.hd_buy_potential
    HAVING SUM(ss.ss_net_paid) > 100000
)
SELECT
    d_year,
    s_state,
    i_category,
    p_channel_tv,
    cd_gender,
    hd_buy_potential,
    total_net_paid,
    total_sales_price,
    total_profit,
    total_return_amount,
    total_return_qty,
    total_quantity,
    return_qty_rate,
    return_amt_rate,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS sales_rank
FROM sales_summary
ORDER BY total_net_paid DESC
LIMIT 100
