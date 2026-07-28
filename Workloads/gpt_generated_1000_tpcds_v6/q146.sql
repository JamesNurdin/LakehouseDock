WITH joined AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_name,
        s.s_state AS store_state,
        w.w_warehouse_name,
        w.w_state AS warehouse_state,
        cc.cc_division_name,
        ca.ca_state AS address_state,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_reversed_charge,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND w.w_state = 'TX'
      AND cc.cc_country = 'United States'
      AND inv.inv_quantity_on_hand > 500
      AND sr.sr_fee > 20
),
agg AS (
    SELECT
        s_store_name,
        w_warehouse_name,
        cc_division_name,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_fee) AS total_fee,
        SUM(sr_reversed_charge) AS total_rev_charge,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS cnt_returns
    FROM joined
    GROUP BY ROLLUP (s_store_name, w_warehouse_name, cc_division_name)
)
SELECT *
FROM (
    SELECT
        s_store_name,
        w_warehouse_name,
        cc_division_name,
        total_return_amt,
        total_fee,
        total_rev_charge,
        total_inventory,
        cnt_returns,
        SUM(total_return_amt) OVER (PARTITION BY s_store_name ORDER BY w_warehouse_name
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_return
    FROM agg
    WHERE total_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns)
) 
UNION ALL
SELECT *
FROM (
    SELECT
        s_store_name,
        w_warehouse_name,
        cc_division_name,
        total_return_amt,
        total_fee,
        total_rev_charge,
        total_inventory,
        cnt_returns,
        SUM(total_return_amt) OVER (PARTITION BY s_store_name ORDER BY w_warehouse_name
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_return
    FROM agg
    WHERE total_return_amt <= (SELECT AVG(sr_return_amt) FROM store_returns)
) 
ORDER BY s_store_name, w_warehouse_name
LIMIT 100
