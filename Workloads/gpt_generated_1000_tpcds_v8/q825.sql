WITH
    intersect_cust AS (
        SELECT cr_refunded_customer_sk AS cust_sk
        FROM catalog_returns
        WHERE cr_fee > 30
        INTERSECT
        SELECT cr_refunded_customer_sk
        FROM catalog_returns
        WHERE cr_fee > 80
    ),
    except_cust AS (
        SELECT cr_refunded_customer_sk AS cust_sk
        FROM catalog_returns
        WHERE cr_fee > 30
        EXCEPT
        SELECT cr_refunded_customer_sk
        FROM catalog_returns
        WHERE cr_fee > 80
    ),
    agg_part AS (
        SELECT
            cc.cc_division_name AS division_name,
            cd.cd_credit_rating AS credit_rating,
            CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category,
            cr.cr_return_amount,
            cr.cr_fee,
            cr.cr_store_credit,
            cr.cr_order_number,
            (SELECT AVG(cr2.cr_fee)
               FROM catalog_returns cr2
               WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk) AS avg_fee_by_center
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE cc.cc_zip = '26534'
          AND cd.cd_education_status = 'College'
          AND cr.cr_fee > 20
          AND cr.cr_store_credit < 500
          AND EXISTS (
                SELECT 1 FROM catalog_returns cr2
                WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
                  AND cr2.cr_fee > 60
          )
          AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_cust)
          AND c.c_customer_sk NOT IN (SELECT cust_sk FROM except_cust)
    ),
    grouped1 AS (
        SELECT
            division_name,
            credit_rating,
            amount_category,
            COUNT(DISTINCT cr_order_number) AS distinct_orders,
            SUM(cr_return_amount) AS total_return_amount,
            AVG(cr_fee) AS avg_fee,
            SUM(cr_store_credit) AS total_store_credit,
            AVG(avg_fee_by_center) AS avg_center_fee,
            ROW_NUMBER() OVER (PARTITION BY division_name ORDER BY SUM(cr_return_amount) DESC) AS rank_by_return,
            SUM(SUM(cr_return_amount)) OVER () AS grand_total_return_amount
        FROM agg_part
        GROUP BY ROLLUP (division_name, credit_rating, amount_category)
        HAVING SUM(cr_return_amount) > 0
    ),
    agg_part2 AS (
        SELECT
            cc.cc_division_name AS division_name,
            cd.cd_credit_rating AS credit_rating,
            CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category,
            cr.cr_return_amount,
            cr.cr_fee,
            cr.cr_store_credit,
            cr.cr_order_number
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE cc.cc_zip = '73951'
          AND cd.cd_education_status = 'Secondary'
          AND cr.cr_fee > 10
          AND cr.cr_store_credit < 1000
          AND NOT EXISTS (
                SELECT 1 FROM catalog_returns cr2
                WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
                  AND cr2.cr_fee > 200
          )
    ),
    grouped2 AS (
        SELECT
            division_name,
            credit_rating,
            amount_category,
            COUNT(DISTINCT cr_order_number) AS distinct_orders,
            SUM(cr_return_amount) AS total_return_amount,
            AVG(cr_fee) AS avg_fee,
            SUM(cr_store_credit) AS total_store_credit,
            ROW_NUMBER() OVER (PARTITION BY division_name ORDER BY SUM(cr_return_amount) DESC) AS rank_by_return
        FROM agg_part2
        GROUP BY CUBE (division_name, credit_rating, amount_category)
        HAVING COUNT(*) > 0
    )
SELECT
    division_name,
    credit_rating,
    amount_category,
    distinct_orders,
    total_return_amount,
    avg_fee,
    total_store_credit,
    rank_by_return
FROM (
    SELECT
        division_name,
        credit_rating,
        amount_category,
        distinct_orders,
        total_return_amount,
        avg_fee,
        total_store_credit,
        rank_by_return
    FROM grouped1
    UNION DISTINCT
    SELECT
        division_name,
        credit_rating,
        amount_category,
        distinct_orders,
        total_return_amount,
        avg_fee,
        total_store_credit,
        rank_by_return
    FROM grouped2
) final_union
ORDER BY division_name ASC NULLS LAST,
         credit_rating ASC,
         total_return_amount DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
