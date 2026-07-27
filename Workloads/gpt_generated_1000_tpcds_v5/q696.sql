WITH joined AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_tax_percentage,
        p.p_promo_id,
        p.p_discount_active,
        sm.sm_carrier,
        sm.sm_contract,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit,
        cs.cs_ext_tax,
        cs.cs_ext_discount_amt,
        ss.ss_ext_discount_amt,
        ws.ws_ext_discount_amt
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        cs.cs_ext_tax > 20
        AND cs.cs_ext_discount_amt BETWEEN 1000 AND 5000
        AND ss.ss_ext_discount_amt > 500
        AND ws.ws_ext_discount_amt < 2000
        AND s.s_tax_percentage >= 0.05
        AND sm.sm_carrier = 'FEDEX'
        AND sm.sm_contract LIKE '%RJn%'
        AND p.p_discount_active = 'Y'
)
SELECT
    s_store_id,
    s_store_name,
    p_promo_id,
    sm_carrier,
    SUM(cs_net_profit + ss_net_profit + ws_net_profit) AS total_profit,
    RANK() OVER (ORDER BY SUM(cs_net_profit + ss_net_profit + ws_net_profit) DESC) AS profit_rank
FROM joined
GROUP BY
    s_store_id,
    s_store_name,
    p_promo_id,
    sm_carrier
ORDER BY profit_rank
LIMIT 100
