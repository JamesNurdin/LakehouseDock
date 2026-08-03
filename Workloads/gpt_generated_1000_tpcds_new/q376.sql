WITH
    cust_filtered AS (
        SELECT
            cd_demo_sk,
            cd_gender,
            cd_marital_status,
            cd_education_status,
            cd_purchase_estimate,
            cd_credit_rating,
            cd_dep_count,
            cd_dep_employed_count,
            cd_dep_college_count
        FROM customer_demographics
        WHERE cd_dep_count BETWEEN 1 AND 5
          AND cd_education_status IN ('Advanced Degree', 'Secondary', 'Primary')
          AND cd_credit_rating <> 'Unknown'
          AND cd_dep_employed_count >= 0
          AND cd_gender IN ('M', 'F')
          AND cd_marital_status = 'S'
    ),
    store_filtered AS (
        SELECT
            sr_returned_date_sk,
            sr_return_time_sk,
            sr_item_sk,
            sr_customer_sk,
            sr_cdemo_sk,
            sr_hdemo_sk,
            sr_addr_sk,
            sr_store_sk,
            sr_reason_sk,
            sr_ticket_number,
            sr_return_quantity,
            sr_return_amt,
            sr_return_tax,
            sr_return_amt_inc_tax,
            sr_fee,
            sr_return_ship_cost,
            sr_refunded_cash,
            sr_reversed_charge,
            sr_store_credit,
            sr_net_loss
        FROM store_returns
        WHERE sr_store_credit > 100
          AND sr_reversed_charge BETWEEN 0 AND 1000
          AND sr_refunded_cash < 2000
          AND sr_return_quantity >= 1
          AND sr_return_amt_inc_tax > 0
          AND sr_cdemo_sk IN (
                SELECT cd_demo_sk
                FROM customer_demographics
                WHERE cd_dep_count >= 2
          )
    ),
    full_joined AS (
        SELECT
            sf.sr_returned_date_sk,
            sf.sr_return_time_sk,
            sf.sr_item_sk,
            sf.sr_customer_sk,
            sf.sr_cdemo_sk,
            sf.sr_hdemo_sk,
            sf.sr_addr_sk,
            sf.sr_store_sk,
            sf.sr_reason_sk,
            sf.sr_ticket_number,
            sf.sr_return_quantity,
            sf.sr_return_amt,
            sf.sr_return_tax,
            sf.sr_return_amt_inc_tax,
            sf.sr_fee,
            sf.sr_return_ship_cost,
            sf.sr_refunded_cash,
            sf.sr_reversed_charge,
            sf.sr_store_credit,
            sf.sr_net_loss,
            cf.cd_gender,
            cf.cd_marital_status,
            cf.cd_education_status,
            cf.cd_purchase_estimate,
            cf.cd_credit_rating,
            cf.cd_dep_count,
            cf.cd_dep_employed_count,
            cf.cd_dep_college_count
        FROM store_filtered sf
        FULL OUTER JOIN cust_filtered cf
          ON sf.sr_cdemo_sk = cf.cd_demo_sk
    ),
    intersect_keys AS (
        SELECT sr_cdemo_sk FROM store_filtered
        INTERSECT
        SELECT cd_demo_sk FROM cust_filtered
    ),
    ranked_data AS (
        SELECT
            fj.*, 
            ROW_NUMBER() OVER (PARTITION BY fj.cd_gender ORDER BY fj.sr_store_credit DESC) AS gender_store_credit_rank,
            CASE
                WHEN fj.sr_store_credit > 300 THEN 'High'
                WHEN fj.sr_store_credit BETWEEN 150 AND 300 THEN 'Medium'
                ELSE 'Low'
            END AS store_credit_category
        FROM full_joined fj
        WHERE fj.sr_cdemo_sk IN (SELECT sr_cdemo_sk FROM intersect_keys)
    ),
    first_select AS (
        SELECT
            gender_store_credit_rank,
            store_credit_category,
            cd_gender,
            sr_store_credit,
            sr_refunded_cash,
            cd_education_status
        FROM ranked_data
        WHERE gender_store_credit_rank <= 10
    ),
    second_select AS (
        SELECT
            gender_store_credit_rank,
            store_credit_category,
            cd_gender,
            sr_store_credit,
            sr_refunded_cash,
            cd_education_status
        FROM ranked_data
        WHERE cd_education_status = 'Advanced Degree'
    )
SELECT *
FROM (
    SELECT * FROM first_select
    UNION DISTINCT
    SELECT * FROM second_select
) final_result
ORDER BY gender_store_credit_rank, sr_store_credit DESC
LIMIT 100
