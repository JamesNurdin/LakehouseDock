WITH
    refunded_agg AS (
        SELECT
            cr_call_center_sk,
            cr_refunded_cdemo_sk AS cd_demo_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_net_loss,
            COUNT(*) AS txn_count
        FROM catalog_returns
        WHERE cr_return_ship_cost > 100
          AND cr_reversed_charge < 500
          AND cr_fee BETWEEN 0 AND 2000
          AND cr_store_credit <> 0
        GROUP BY cr_call_center_sk, cr_refunded_cdemo_sk
    ),
    returning_agg AS (
        SELECT
            cr_call_center_sk,
            cr_returning_cdemo_sk AS cd_demo_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_net_loss,
            COUNT(*) AS txn_count
        FROM catalog_returns
        WHERE cr_return_ship_cost > 100
          AND cr_reversed_charge < 500
          AND cr_fee BETWEEN 0 AND 2000
          AND cr_store_credit <> 0
        GROUP BY cr_call_center_sk, cr_returning_cdemo_sk
    ),
    unioned AS (
        SELECT
            cc.cc_division_name      AS division_name,
            cd.cd_education_status   AS education_status,
            agg.total_return_amount,
            agg.total_net_loss,
            agg.txn_count
        FROM refunded_agg agg
        JOIN call_center cc
            ON agg.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd
            ON agg.cd_demo_sk = cd.cd_demo_sk
        WHERE cd.cd_purchase_estimate >= 1000
          AND cd.cd_dep_college_count <= 3
          AND cc.cc_street_type = 'Avenue'
          AND cc.cc_gmt_offset BETWEEN -5 AND 5

        UNION DISTINCT

        SELECT
            cc.cc_division_name      AS division_name,
            cd.cd_education_status   AS education_status,
            agg.total_return_amount,
            agg.total_net_loss,
            agg.txn_count
        FROM returning_agg agg
        JOIN call_center cc
            ON agg.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd
            ON agg.cd_demo_sk = cd.cd_demo_sk
        WHERE cd.cd_education_status = 'Advanced Degree'
          AND cd.cd_purchase_estimate <= 3000
          AND cc.cc_division_name = 'anti'
          AND cc.cc_street_type = 'Boulevard'
    )
SELECT
    division_name,
    education_status,
    SUM(total_return_amount) AS sum_return_amount,
    AVG(total_net_loss)      AS avg_net_loss,
    SUM(txn_count)           AS total_transactions
FROM unioned
WHERE total_return_amount > (SELECT MAX(cr_return_amount) FROM catalog_returns)
GROUP BY division_name, education_status
HAVING SUM(total_return_amount) > 10000
ORDER BY avg_net_loss DESC, division_name ASC
OFFSET 20 ROWS
FETCH NEXT 100 ROWS ONLY
