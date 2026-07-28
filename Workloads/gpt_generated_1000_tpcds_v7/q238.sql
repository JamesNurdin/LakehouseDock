WITH base AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_brand,
        cp.cp_department,
        sm.sm_type AS ship_mode_type,
        hd.hd_buy_potential,
        ib.ib_lower_bound AS income_lower,
        t.t_hour,
        t.t_sub_shift,
        SUM(cs.cs_net_paid) AS catalog_sales_net,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_ext,
        SUM(cr.cr_return_amount) AS catalog_returns_amount,
        SUM(ss.ss_net_paid) AS store_sales_net,
        SUM(ss.ss_ext_sales_price) AS store_sales_ext,
        SUM(sr.sr_return_amt) AS store_returns_amount,
        SUM(wr.wr_return_amt) AS web_returns_amount,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
        AND i.i_current_price > 50
        AND cp.cp_department = 'Electronics'
        AND sm.sm_type = 'AIR'
        AND ib.ib_lower_bound >= 50000
    GROUP BY
        i.i_item_id,
        i.i_category,
        i.i_brand,
        cp.cp_department,
        sm.sm_type,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        t.t_hour,
        t.t_sub_shift
)
SELECT
    *,
    SUM(catalog_sales_net) OVER (PARTITION BY i_category) AS category_catalog_sales_net_total,
    RANK() OVER (ORDER BY catalog_sales_net DESC) AS sales_rank
FROM base
ORDER BY catalog_sales_net DESC
LIMIT 100
