WITH sales_base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state IN ('CA', 'TX')
      AND i.i_brand = 'Brand#12'
      AND ib.ib_upper_bound <= 170000
      AND td.t_hour BETWEEN 9 AND 21
    GROUP BY
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
unioned_sales AS (
    SELECT
        s_store_id,
        s_state,
        i_item_id,
        i_category,
        i_brand,
        total_sales,
        total_profit,
        total_return_amount,
        transaction_count,
        total_on_hand
    FROM sales_base
    WHERE s_state = 'CA'
    UNION
    SELECT
        s_store_id,
        s_state,
        i_item_id,
        i_category,
        i_brand,
        total_sales,
        total_profit,
        total_return_amount,
        transaction_count,
        total_on_hand
    FROM sales_base
    WHERE s_state = 'TX' AND total_sales > 5000
)
SELECT
    u.s_state,
    u.i_category,
    SUM(u.total_sales) AS sum_sales,
    AVG(u.total_profit) AS avg_profit,
    SUM(u.total_return_amount) AS sum_returns,
    COUNT(*) AS row_cnt,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2 WHERE ib2.ib_lower_bound > 100000) AS max_income_upper_bound
FROM unioned_sales u
WHERE u.total_on_hand > 0
GROUP BY u.s_state, u.i_category
HAVING SUM(u.total_sales) > 10000
ORDER BY sum_sales DESC
LIMIT 100
