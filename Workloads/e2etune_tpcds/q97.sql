WITH returns_agg AS (
    SELECT
        cc.cc_manager,
        s.s_store_name AS s_store_name,
        p.p_promo_name,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM call_center cc
    JOIN store s
      ON cc.cc_state = s.s_state
    JOIN promotion p
      ON p.p_start_date_sk >= cc.cc_open_date_sk
     AND (cc.cc_closed_date_sk IS NULL OR p.p_end_date_sk <= cc.cc_closed_date_sk)
    JOIN web_returns wr
      ON wr.wr_item_sk = p.p_item_sk
     AND wr.wr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN inventory inv
      ON inv.inv_item_sk = p.p_item_sk
     AND inv.inv_date_sk = p.p_start_date_sk
    WHERE cc.cc_manager IN ('Bob Belcher', 'Felipe Perkins')
      AND cc.cc_division = 3
      AND p.p_cost > 0
    GROUP BY cc.cc_manager, s.s_store_name, p.p_promo_name
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    ra.cc_manager,
    ra.s_store_name,
    ra.p_promo_name,
    ra.num_returns,
    ra.total_net_loss,
    ra.total_return_amount_inc_tax,
    ra.avg_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY ra.cc_manager ORDER BY ra.total_net_loss DESC) AS manager_store_rank
FROM returns_agg ra
ORDER BY ra.total_net_loss DESC
LIMIT 100
