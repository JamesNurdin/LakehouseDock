WITH base AS (
   SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_discount_active,
        p.p_promo_name,
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_department,
        t.t_hour,
        t.t_shift,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        r.r_reason_desc,
        ss.ss_net_paid   AS ss_net_paid,
        ss.ss_ext_discount_amt AS ss_ext_discount_amt,
        ws.ws_net_paid   AS ws_net_paid,
        ws.ws_ext_discount_amt AS ws_ext_discount_amt
   FROM catalog_sales cs
   JOIN item i               ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
   JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t          ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN store_sales ss     ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN web_sales ws       ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
   WHERE
        cp.cp_start_date_sk BETWEEN 2450800 AND 2451300
        AND p.p_discount_active = 'Y'
        AND i.i_category = 'Electronics'
        AND c.c_preferred_cust_flag = 'Y'
        AND hd.hd_buy_potential = '5000-9999'
        AND ib.ib_upper_bound <= 80000
        AND cs.cs_ext_discount_amt > 100
        AND ss.ss_ext_discount_amt > 50
        AND ws.ws_ext_discount_amt > 20
        AND EXISTS (
            SELECT 1 FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_warehouse_sk = w.w_warehouse_sk
              AND inv.inv_quantity_on_hand > 0
        )
)
SELECT
    item_id,
    sold_date_sk,
    total_sales,
    profit_flag,
    sales_rank,
    channel_type
FROM (
    SELECT
        i_item_id            AS item_id,
        cs_sold_date_sk      AS sold_date_sk,
        (cs_net_paid + COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) AS total_sales,
        CASE WHEN cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_flag,
        RANK() OVER (PARTITION BY cs_sold_date_sk ORDER BY (cs_net_paid + COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) DESC) AS sales_rank,
        'All'                AS channel_type,
        cs_quantity
    FROM base
    WHERE cs_quantity > 5
) a
UNION DISTINCT
SELECT
    item_id,
    sold_date_sk,
    total_sales,
    profit_flag,
    sales_rank,
    channel_type
FROM (
    SELECT
        i_item_id            AS item_id,
        cs_sold_date_sk      AS sold_date_sk,
        (cs_net_paid + COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) AS total_sales,
        CASE WHEN cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_flag,
        RANK() OVER (PARTITION BY cs_sold_date_sk ORDER BY (cs_net_paid + COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) DESC) AS sales_rank,
        'All'                AS channel_type,
        cs_quantity
    FROM base
    WHERE cs_quantity <= 5
) b
ORDER BY sold_date_sk, sales_rank
LIMIT 100
