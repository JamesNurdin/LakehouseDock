WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 5
      AND ss.ss_ext_discount_amt > 100
      AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2452500
),
joined AS (
    SELECT
        bs.ss_sold_date_sk,
        bs.ss_ticket_number,
        bs.ss_item_sk,
        bs.ss_store_sk,
        bs.ss_quantity,
        bs.ss_ext_discount_amt,
        bs.ss_ext_sales_price,
        bs.ss_net_profit,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_purpose,
        p.p_channel_tv,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        sr.sr_store_credit,
        sr.sr_return_quantity
    FROM base_sales bs
    JOIN household_demographics hd
        ON bs.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON bs.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON bs.ss_ticket_number = sr.sr_ticket_number
        AND bs.ss_item_sk = sr.sr_item_sk
        AND hd.hd_demo_sk = sr.sr_hdemo_sk
    WHERE p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 20000
      AND hd.hd_vehicle_count >= 2
      AND sr.sr_return_amt_inc_tax > 50
),
ranked AS (
    SELECT
        j.ss_store_sk,
        j.p_promo_name,
        j.ss_net_profit,
        j.sr_return_amt_inc_tax,
        j.hd_vehicle_count,
        j.ib_lower_bound,
        RANK() OVER (PARTITION BY j.ss_store_sk ORDER BY j.ss_net_profit DESC) AS profit_rank,
        (SELECT AVG(ss2.ss_ext_discount_amt)
         FROM store_sales ss2
         WHERE ss2.ss_promo_sk = j.p_promo_sk) AS avg_discount_per_promo,
        rc.return_cnt
    FROM joined j
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS return_cnt
        FROM store_returns sr2
        WHERE sr2.sr_hdemo_sk = j.hd_demo_sk
          AND sr2.sr_returned_date_sk = j.sr_returned_date_sk
    ) rc
    WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = j.p_promo_sk
          AND p2.p_channel_tv = 'Y'
    )
)
SELECT DISTINCT
    r.ss_store_sk,
    r.p_promo_name,
    r.profit_rank,
    r.ss_net_profit,
    r.avg_discount_per_promo,
    r.return_cnt,
    r.sr_return_amt_inc_tax
FROM ranked r
EXCEPT
SELECT
    r2.ss_store_sk,
    r2.p_promo_name,
    r2.profit_rank,
    r2.ss_net_profit,
    r2.avg_discount_per_promo,
    r2.return_cnt,
    r2.sr_return_amt_inc_tax
FROM ranked r2
WHERE r2.sr_return_amt_inc_tax > 5000
ORDER BY profit_rank
LIMIT 100
