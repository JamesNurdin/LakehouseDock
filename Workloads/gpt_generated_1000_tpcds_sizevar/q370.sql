/*
Goal: Identify dates in 2001 where a store closed but the corresponding web site did not, then further filter those dates to keep only those that appear in catalog returns but not in inventory. The query demonstrates:
- a FULL OUTER JOIN between stores and web sites on matching closed dates,
- a set subtraction (EXCEPT) to get catalog‑return dates that are absent from inventory,
- additional joins to the date dimension for filtering by year,
- ordering and limiting the final result.
*/
WITH store_keys AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_closed_date_sk AS date_sk
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
website_keys AS (
    SELECT
        w.web_site_id AS website_id,
        w.web_close_date_sk AS date_sk
    FROM web_site w
    JOIN date_dim d ON w.web_close_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
full_join AS (
    SELECT
        COALESCE(s.store_id, w.website_id) AS entity_id,
        s.store_id,
        w.website_id,
        COALESCE(s.date_sk, w.date_sk) AS close_date_sk
    FROM store_keys s
    FULL OUTER JOIN website_keys w ON s.date_sk = w.date_sk
),
inventory_dates AS (
    SELECT inv_date_sk FROM inventory
),
catalog_return_dates AS (
    SELECT cr_returned_date_sk FROM catalog_returns
),
return_excluding_inventory AS (
    SELECT cr_returned_date_sk FROM catalog_return_dates
    EXCEPT
    SELECT inv_date_sk FROM inventory_dates
)
SELECT
    fj.entity_id,
    fj.store_id,
    fj.website_id,
    fj.close_date_sk,
    rei.cr_returned_date_sk AS return_date_sk
FROM full_join fj
JOIN return_excluding_inventory rei
    ON rei.cr_returned_date_sk = fj.close_date_sk
ORDER BY fj.close_date_sk DESC
LIMIT 100
