WITH
    intersected_customers AS (
        SELECT c_customer_sk FROM customer WHERE c_birth_year > 1960
        INTERSECT
        SELECT cr_refunded_customer_sk FROM catalog_returns
    ),
    joined_data AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_ship_mode_sk,
            cr.cr_refunded_customer_sk,
            c.c_customer_id,
            c.c_birth_year,
            cd.cd_gender,
            cd.cd_credit_rating,
            hd.hd_buy_potential,
            sm.sm_carrier,
            s.s_store_name,
            s.s_state,
            sr.sr_return_amt,
            sr.sr_return_quantity,
            sr.sr_store_sk
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM intersected_customers)
          AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
          AND sm.sm_carrier = 'FedEx'
    ),
    ranked_data AS (
        SELECT
            jd.*, 
            ROW_NUMBER() OVER (PARTITION BY jd.c_customer_id ORDER BY jd.cr_return_amount DESC) AS rn,
            SUM(jd.cr_return_amount) OVER (
                PARTITION BY jd.c_customer_id 
                ORDER BY jd.cr_order_number 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS cum_return_amount,
            LAG(jd.cr_return_amount) OVER (
                PARTITION BY jd.c_customer_id ORDER BY jd.cr_order_number
            ) AS prev_return_amount,
            (
                SELECT SUM(sr2.sr_return_amt)
                FROM store_returns sr2
                WHERE sr2.sr_customer_sk = jd.cr_refunded_customer_sk
            ) AS total_store_return_amt
        FROM joined_data jd
    ),
    final_union AS (
        SELECT
            rd.c_customer_id,
            rd.c_birth_year,
            rd.cd_gender,
            rd.cd_credit_rating,
            rd.hd_buy_potential,
            rd.sm_carrier,
            rd.s_store_name,
            rd.s_state,
            rd.cr_order_number,
            rd.cr_return_amount,
            rd.cum_return_amount,
            rd.prev_return_amount,
            rd.total_store_return_amt,
            RANK() OVER (ORDER BY rd.cum_return_amount DESC) AS overall_rank
        FROM ranked_data rd
        WHERE rd.rn = 1

        UNION

        SELECT
            rd.c_customer_id,
            rd.c_birth_year,
            rd.cd_gender,
            rd.cd_credit_rating,
            rd.hd_buy_potential,
            rd.sm_carrier,
            rd.s_store_name,
            rd.s_state,
            rd.cr_order_number,
            rd.cr_return_amount,
            rd.cum_return_amount,
            rd.prev_return_amount,
            rd.total_store_return_amt,
            RANK() OVER (ORDER BY rd.cum_return_amount DESC) AS overall_rank
        FROM ranked_data rd
        WHERE rd.rn = 2
    )
SELECT *
FROM final_union
ORDER BY overall_rank, c_customer_id
LIMIT 100
