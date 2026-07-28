WITH joined AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        p.p_promo_name,
        i.i_category,
        i.i_size,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        sr.sr_return_amt,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- store_sales linked via common dimensions
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    -- store_returns linked to store_sales
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    -- web_returns linked to item & demographics
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        cc.cc_state = 'CA'
        AND i.i_size = 'large'
        AND ib.ib_lower_bound >= 50000
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
        AND sr.sr_return_amt > 1000
)
SELECT
    cc_name,
    p_promo_name,
    i_category,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    RANK() OVER (ORDER BY (SUM(cs_net_paid) + SUM(ss_net_paid) - SUM(sr_return_amt) - SUM(wr_return_amt)) DESC) AS profit_rank
FROM joined
GROUP BY
    cc_name,
    p_promo_name,
    i_category,
    ib_lower_bound,
    ib_upper_bound
ORDER BY profit_rank
LIMIT 100
