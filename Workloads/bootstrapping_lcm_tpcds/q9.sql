WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ds.d_date AS store_closed_date,
        dr.d_year,
        dr.d_quarter_name,
        dr.d_week_seq,
        s.s_floor_space,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        ROUND(SUM(sr.sr_return_amt) / NULLIF(s.s_floor_space, 0), 2) AS return_per_sqft,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        AVG(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS pct_high_buy_potential,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_return_date
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim ds ON s.s_closed_date_sk = ds.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = dr.d_date_sk
    WHERE dr.d_year BETWEEN 2019 AND 2021
      AND dr.d_weekend = 'Y'
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        ds.d_date,
        dr.d_year,
        dr.d_quarter_name,
        dr.d_week_seq,
        s.s_floor_space
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.store_closed_date,
    a.d_year,
    a.d_quarter_name,
    a.d_week_seq,
    a.num_returns,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_quantity,
    a.return_per_sqft,
    a.avg_vehicle_count,
    a.pct_high_buy_potential,
    a.avg_inventory_on_return_date,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.d_year, a.d_week_seq) AS return_seq_num
FROM aggregated a
ORDER BY a.d_year, a.d_week_seq, a.total_return_amount DESC
LIMIT 100
