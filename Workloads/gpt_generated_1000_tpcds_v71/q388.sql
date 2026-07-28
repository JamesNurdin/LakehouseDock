WITH sales_base AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
),
joined AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_rec_end_date,
        cc.cc_name,
        cc.cc_employees,
        cp.cp_department,
        cp.cp_type,
        p.p_promo_name,
        p.p_discount_active,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_address_sk,
        td.t_time_sk,
        inv.inv_quantity_on_hand,
        b.cs_quantity,
        b.cs_net_profit,
        b.cs_order_number,
        sr.sr_net_loss,
        sr.sr_customer_sk
    FROM sales_base b
    JOIN call_center cc
        ON b.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON b.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON b.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON b.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON b.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON b.cs_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td
        ON b.cs_sold_time_sk = td.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
           AND sr.sr_hdemo_sk = hd.hd_demo_sk
           AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE
        s.s_rec_end_date > DATE '2000-01-01'
        AND cc.cc_employees >= 50
        AND cp.cp_type = 'catalog'
        AND p.p_discount_active = 'Y'
        AND ib.ib_lower_bound >= 30000
        AND NOT EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_customer_sk = sr.sr_customer_sk
              AND sr2.sr_net_loss > 500
        )
)
SELECT
    s_store_id,
    s_city,
    cc_name,
    cp_department,
    p_promo_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(cs_net_profit) AS store_profit,
    COUNT(DISTINCT cs_order_number) AS orders,
    RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank,
    CASE WHEN SUM(cs_quantity) > 1000 THEN 'HIGH' ELSE 'LOW' END AS volume_category
FROM joined
GROUP BY
    s_store_id,
    s_city,
    cc_name,
    cp_department,
    p_promo_name,
    ib_lower_bound,
    ib_upper_bound
ORDER BY store_profit DESC
LIMIT 100
