WITH daily_returns AS (
    SELECT
        d.d_date AS d_date,
        ws.web_name AS web_name,
        r.r_reason_desc AS r_reason_desc,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        MAX(inv.inv_quantity_on_hand) AS max_inventory_on_hand
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND r.r_reason_desc LIKE '%defect%'
      AND ws.web_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_start_date_sk = d.d_date_sk
              AND p.p_channel_tv = 'N'
              AND p.p_promo_name LIKE '%bar%'
          )
    GROUP BY d.d_date, ws.web_name, r.r_reason_desc
)
SELECT
    d_date,
    web_name,
    r_reason_desc,
    total_return_qty,
    total_net_loss,
    max_inventory_on_hand,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM daily_returns
ORDER BY total_net_loss DESC
LIMIT 100
