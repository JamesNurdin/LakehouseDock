WITH
    sub1 AS (
        SELECT
            catalog_returns.cr_order_number,
            catalog_returns.cr_return_amt_inc_tax,
            household_demographics.hd_buy_potential,
            catalog_returns.cr_returning_addr_sk,
            ARRAY[catalog_returns.cr_return_amount, catalog_returns.cr_return_tax] AS amt_array
        FROM catalog_returns
        FULL OUTER JOIN household_demographics
            ON catalog_returns.cr_refunded_hdemo_sk = household_demographics.hd_demo_sk
        WHERE catalog_returns.cr_return_amount > 100
    ),
    unnest_sub1 AS (
        SELECT
            sub1.cr_order_number,
            sub1.cr_return_amt_inc_tax,
            sub1.hd_buy_potential,
            amt,
            sub1.cr_returning_addr_sk
        FROM sub1
        CROSS JOIN UNNEST(sub1.amt_array) AS t(amt)
    ),
    sub2 AS (
        SELECT
            catalog_returns.cr_order_number,
            catalog_returns.cr_return_amt_inc_tax,
            household_demographics.hd_buy_potential,
            catalog_returns.cr_returning_addr_sk,
            ARRAY[catalog_returns.cr_return_amount, catalog_returns.cr_return_tax] AS amt_array
        FROM catalog_returns
        FULL OUTER JOIN household_demographics
            ON catalog_returns.cr_returning_hdemo_sk = household_demographics.hd_demo_sk
        WHERE household_demographics.hd_dep_count >= 5
    ),
    unnest_sub2 AS (
        SELECT
            sub2.cr_order_number,
            sub2.cr_return_amt_inc_tax,
            sub2.hd_buy_potential,
            amt,
            sub2.cr_returning_addr_sk
        FROM sub2
        CROSS JOIN UNNEST(sub2.amt_array) AS t(amt)
    )
SELECT
    cr_order_number,
    cr_return_amt_inc_tax,
    hd_buy_potential,
    amt,
    cr_returning_addr_sk
FROM unnest_sub1
UNION ALL
SELECT
    cr_order_number,
    cr_return_amt_inc_tax,
    hd_buy_potential,
    amt,
    cr_returning_addr_sk
FROM unnest_sub2
ORDER BY cr_return_amt_inc_tax DESC, amt DESC
LIMIT 100
