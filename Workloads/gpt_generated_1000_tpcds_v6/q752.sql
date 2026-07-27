WITH base_agg AS (
    SELECT
        r.r_reason_desc AS r_reason_desc,
        d_sr.d_year AS d_year,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count
    FROM store_returns sr
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sr.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sr.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_sr.d_date_sk
       AND p.p_end_date_sk   = d_sr.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year BETWEEN 2000 AND 2002
      AND hd.hd_income_band_sk IN (1, 2, 3, 4)
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_start_date_sk = d_sr.d_date_sk
            AND p2.p_end_date_sk   = d_sr.d_date_sk
            AND p2.p_promo_name = 'Clearance Sale'
      )
    GROUP BY r.r_reason_desc, d_sr.d_year
)
SELECT
    t.reason_desc,
    t.year,
    t.total_net_loss,
    t.avg_inventory_on_hand,
    t.total_promo_cost,
    t.warehouse_count,
    RANK() OVER (PARTITION BY t.year ORDER BY t.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        r_reason_desc AS reason_desc,
        d_year AS year,
        (store_net_loss + web_net_loss) AS total_net_loss,
        avg_inventory_on_hand,
        total_promo_cost,
        warehouse_count
    FROM base_agg
) t
WHERE t.total_net_loss > 1000
ORDER BY t.year, loss_rank
LIMIT 100
