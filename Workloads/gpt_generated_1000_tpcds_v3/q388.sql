WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_item_sk,
        cc.cc_call_center_id,
        cc.cc_gmt_offset,
        cc.cc_rec_start_date,
        cp.cp_catalog_page_number,
        cp.cp_description,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_buy_potential
    FROM catalog_sales cs
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
)
SELECT
    sd.cs_order_number,
    sd.cc_call_center_id,
    sd.cp_catalog_page_number,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.hd_vehicle_count,
    sd.cs_quantity,
    sd.cs_net_paid,
    sd.cs_net_profit,
    r.r_reason_desc,
    RANK() OVER (PARTITION BY sd.cc_call_center_id ORDER BY sd.cs_net_profit DESC) AS profit_rank_per_call_center
FROM sales_data sd
INNER JOIN catalog_returns cr
    ON cr.cr_order_number = sd.cs_order_number
    AND cr.cr_item_sk = sd.cs_item_sk
INNER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    sd.cs_quantity > 5
    AND sd.cs_net_paid > 1000
    AND sd.cp_catalog_page_number IN (5, 12, 21)
    AND sd.cd_gender = 'M'
    AND sd.cd_marital_status = 'M'
    AND sd.hd_vehicle_count >= 2
    AND sd.cc_gmt_offset BETWEEN -5 AND 5
    AND sd.cc_rec_start_date <= DATE '2001-01-01'
    AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        INNER JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        WHERE
            sr.sr_cdemo_sk = sd.cs_bill_cdemo_sk
            AND sr.sr_hdemo_sk = sd.cs_bill_hdemo_sk
            AND sr.sr_reason_sk = r.r_reason_sk
            AND s.s_state = 'CA'
            AND sr.sr_return_quantity > 0
            AND sr.sr_net_loss < 500
    )
ORDER BY profit_rank_per_call_center ASC, sd.cs_net_profit DESC
LIMIT 100
