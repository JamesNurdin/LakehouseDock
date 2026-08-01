WITH joined_all AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_date,
        d.d_year,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        p.p_promo_id AS promo_id,
        p.p_discount_active AS promo_discount_active,
        cust_ref.c_customer_id AS refunded_customer_id,
        cust_ret.c_customer_id AS returning_customer_id,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        inc_ref.ib_upper_bound AS refunded_income_upper,
        inc_ret.ib_upper_bound AS returning_income_upper,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        s.s_store_name,
        cp.cp_catalog_number,
        ws.web_name,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_returns wr
    INNER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    INNER JOIN customer cust_ref
        ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
    INNER JOIN customer cust_ret
        ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
    INNER JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    INNER JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    INNER JOIN income_band inc_ref
        ON hd_ref.hd_income_band_sk = inc_ref.ib_income_band_sk
    INNER JOIN income_band inc_ret
        ON hd_ret.hd_income_band_sk = inc_ret.ib_income_band_sk
    INNER JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    INNER JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    INNER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    INNER JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Electronics'
      AND inc_ref.ib_upper_bound > 100000
)
SELECT
    d_date,
    i_category,
    i_current_price,
    promo_id,
    promo_discount_active,
    refunded_customer_id,
    returning_customer_id,
    refunded_state,
    returning_state,
    r_reason_desc,
    inv_quantity_on_hand,
    w_warehouse_name,
    s_store_name,
    cp_catalog_number,
    web_name,
    total_return_amt,
    total_return_qty,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_return_amt DESC) AS category_rank,
    SUM(total_return_amt) OVER (PARTITION BY i_category ORDER BY d_date
                                ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS moving_sum_30d
FROM (
    SELECT
        d_date,
        i_category,
        i_current_price,
        promo_id,
        promo_discount_active,
        refunded_customer_id,
        returning_customer_id,
        refunded_state,
        returning_state,
        r_reason_desc,
        inv_quantity_on_hand,
        w_warehouse_name,
        s_store_name,
        cp_catalog_number,
        web_name,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_qty
    FROM joined_all
    GROUP BY
        d_date,
        i_category,
        i_current_price,
        promo_id,
        promo_discount_active,
        refunded_customer_id,
        returning_customer_id,
        refunded_state,
        returning_state,
        r_reason_desc,
        inv_quantity_on_hand,
        w_warehouse_name,
        s_store_name,
        cp_catalog_number,
        web_name
    HAVING SUM(wr_return_amt) > 500
) agg
ORDER BY total_return_amt DESC
LIMIT 100
