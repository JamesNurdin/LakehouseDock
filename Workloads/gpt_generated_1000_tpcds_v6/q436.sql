WITH base_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cr.cr_return_amount,
        cp.cp_department,
        cp.cp_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        s.s_store_id,
        s.s_state,
        ws.ws_net_paid AS ws_net_paid,
        wp.wp_type,
        (cs.cs_net_paid - cr.cr_return_amount + ws.ws_net_paid) AS total_net,
        CASE
            WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle'
            WHEN hd.hd_vehicle_count = 1 THEN 'SingleVehicle'
            ELSE 'LowVehicle'
        END AS vehicle_category
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN store_sales ss ON ss.ss_cdemo_sk = cd.cd_demo_sk AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON s.s_store_sk = ss.ss_store_sk
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE cp.cp_type = 'Online'
      AND cs.cs_quantity > 1
      AND cr.cr_return_amount > 0
      AND s.s_state = 'CA'
      AND wp.wp_type = 'Content'
      AND hd.hd_buy_potential = '1001-5000'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_return_amt > 0
      )
),
agg_data AS (
    SELECT
        s_store_id,
        cp_department,
        vehicle_category,
        SUM(total_net) AS sum_total_net,
        COUNT(*) AS txn_count
    FROM base_data
    GROUP BY s_store_id, cp_department, vehicle_category
)
SELECT
    s_store_id,
    cp_department,
    vehicle_category,
    sum_total_net,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY sum_total_net DESC) AS rn_store,
    RANK() OVER (ORDER BY sum_total_net DESC) AS rank_overall
FROM agg_data
ORDER BY sum_total_net DESC
LIMIT 100
